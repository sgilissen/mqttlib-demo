#tag Class
Protected Class ClientConnection
	#tag Method, Flags = &h21
		Private Sub ClearSession()
		  //-- Clear the session after a disconnection
		  
		  Self.pConnected = False
		  
		  // Stop the timers
		  Self.pPeriodicCheckTimer.Mode = Timer.ModeOff
		  Self.pKeepAliveTimer.Mode = Xojo.Core.Timer.Modes.Off
		  
		  // Clear the dictionaries
		  Self.pPacketsAwaitingReply.RemoveAll
		  Self.pPacketsAwaitingReplyTimeout.RemoveAll
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Connect()
		  //-- Initiates the connection process by opening the raw connection
		  // The next step will occured in the HandleRawConnectionConnected() method
		  
		  If MQTTLib.VerboseMode Then System.DebugLog CurrentMethodName
		  
		  Self.pRawConnection.Open
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor()
		  //-- Initialize the basic stuff
		  
		  If MQTTLib.VerboseMode Then System.DebugLog CurrentMethodName
		  
		  // Create the sent packet dictionary
		  Self.pPacketsAwaitingReply = New Xojo.Core.Dictionary
		  Self.pPacketsAwaitingReplyTimeout = New Xojo.Core.Dictionary
		  
		  // Create the keep alive timer
		  Self.pKeepAliveTimer = New Xojo.Core.Timer
		  
		  // and wire it
		  AddHandler Self.pKeepAliveTimer.Action, WeakAddressOf Self.HandleKeepAliveTimerAction
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Disconnect()
		  //-- Disconnect the broker
		  
		  If MQTTLib.VerboseMode Then System.DebugLog CurrentMethodName
		  
		  If Not ( Self.pRawConnection Is Nil ) Then Self.pRawConnection.Close
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub HandleKeepAliveTimerAction(inTimer As Xojo.Core.Timer)
		  #pragma Unused inTimer
		  
		  // As simple as this
		  Self.PingBroker
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub HandlePeriodicCheck(inTimer As Timer)
		  
		  // Go through all stored packet to check if they ar all still valid
		  Dim theTime As Double = Microseconds
		  
		  For Each entry As Xojo.Core.DictionaryEntry In Self.pPacketsAwaitingReplyTimeout
		    
		    If entry.Value < theTime Then
		      // Retrieve the packet
		      Dim thePacket As MQTTLib.ControlPacket = Self.pPacketsAwaitingReply.Value( entry.Key )
		      Dim thePacketID As UInt16 = entry.key
		      
		      // We have a timed out packet
		      Self.ProcessProtocolError( CurrentMethodName, "A " + thePacket.TypeString + " packet with ID " + Str(  thePacketID ) + " has timed out.", MQTTLib.Error.TimedOut )
		      Return
		      
		    End If
		    
		  Next
		  
		  // All is good... for now!
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub HandlePINGTimedOut()
		  //-- The last ping has timed out
		  Static theCallCount As Integer
		  
		  theCallCount = theCallCount + 1
		  If theCallCount = 2 then Break 
		  Self.ProcessProtocolError( CurrentMethodName, Str( theCallCount ) + " - No response from the broker when pinged.", MQTTLib.Error.PINGTimedOut )
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub HandleRawConnectionConnected(inRawConnection As MQTTLib.RawConnection)
		  //-- The socket adapter is connected, let's open the MQTT connection
		  
		  #Pragma Unused inRawConnection
		  
		  If MQTTLib.VerboseMode Then System.DebugLog CurrentMethodName
		  
		  // Create the CONNECT control packet with the options passed to the constructor
		  Dim theCONNECTPacket As New MQTTLib.ControlPacket( MQTTLib.ControlPacket.Type.CONNECT, Self.pConnectionSetup )
		  
		  // Send the packet
		  Self.SendControlPacket theCONNECTPacket
		  
		  // Store the time it was sent
		  Self.pPacketsAwaitingReply.Value( kCONNECTDictionaryKey ) = Microseconds
		  
		  // Start the periodic checker timer
		  Self.pPeriodicCheckTimer.Mode = Timer.ModeMultiple
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub HandleRawConnectionControlPacketReceived(inRawConnection As MQTTLib.RawConnection, inControlPacket As MQTTLib.ControlPacket)
		  //-- A new control packet is available
		  
		  #Pragma Unused inRawConnection
		  
		  If MQTTLib.VerboseMode Then System.DebugLog CurrentMethodName
		  
		  Select Case inControlPacket.Type
		    
		  Case MQTTLib.ControlPacket.Type.CONNACK
		    Self.ProcessCONNACK( MQTTLib.OptionsCONNACK( inControlPacket.Options ) )
		    
		  Case MQTTLib.ControlPacket.Type.PINGRESP
		    Self.ProcessPINGRESP
		    
		  Case MQTTLib.ControlPacket.Type.SUBACK
		    Self.ProcessSUBACK( MQTTLib.OptionsSUBACK( inControlPacket.Options ) )
		    
		  Case MQTTLib.ControlPacket.Type.PUBLISH
		    Self.ProcessPUBLISH MQTTLib.OptionsPUBLISH( inControlPacket.Options )
		    
		  Case MQTTLib.ControlPacket.Type.PUBACK
		    Self.ProcessPUBACK MQTTLib.OptionsPUBACK( inControlPacket.Options )
		    
		  Case MQTTLib.ControlPacket.Type.PUBCOMP
		    Self.ProcessPUBCOMP MQTTLib.OptionsPUBCOMP( inControlPacket.Options )
		    
		  Case MQTTLib.ControlPacket.Type.PUBREC
		    Self.ProcessPUBREC MQTTLib.OptionsPUBREC( inControlPacket.Options )
		    
		  Case MQTTLib.ControlPacket.Type.PUBREL
		    Self.ProcessPUBREL MQTTLib.OptionsPUBREL( inControlPacket.Options )
		    
		  Case MQTTLib.ControlPacket.Type.UNSUBACK
		    Self.ProcessUNSUBACK MQTTLib.OptionsUNSUBACK( inControlPacket.Options )
		    
		  Else
		    Self.ProcessProtocolError( CurrentMethodName, "Unsupported control packet type #" _
		    + Str( Integer( inControlPacket.Type ) ) + ".", MQTTLib.Error.UnsupportedControlPacketType )
		    
		  End Select
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub HandleRawConnectionError(inRawConnection As MQTTLib.RawConnection, inMessage As String, inError As MQTTLib.Error)
		  //-- Handles an error from the raw connection
		  
		  If MQTTLib.VerboseMode Then System.DebugLog CurrentMethodName
		  
		  // Clear the session state if we are still connected
		  If Self.pConnected = True Then Self.ClearSession
		  
		  // Signal the error to the subclass
		  RaiseEvent Error( inMessage, inError )
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub HandleResponseTimeOut()
		  
		  If MQTTLib.VerboseMode Then System.DebugLog CurrentMethodName
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function NewPacketID() As UInt16
		  //-- Generate a non-zero unused packetID.
		  
		  #Pragma DisableBackgroundTasks
		  
		  Do
		    
		    // ** Note **
		    // There is a possibility that this loop turn into an endless one.
		    // but it is unlikely that 65535 packetIDs are used at the same time.
		    
		    // Increment the counter to the next ID
		    Self.pPacketIDCounter = Self.pPacketIDCounter + 1
		    
		    // PacketID are non-zero.
		    If pPacketIDCounter = 0 Then Self.pPacketIDCounter = 1
		    
		    // If this packetID is already used, try the next one.
		  Loop Until Not Self.pPacketsAwaitingReply.HasKey( Self.pPacketIDCounter ) 
		  
		  // Return the new unused packet
		  Return Self.pPacketIDCounter
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub PingBroker()
		  //-- Send a PING to the broker.
		  
		  // Give Me a ping, Vassily. One ping only, please.
		  Self.SendControlPacket( New MQTTLib.ControlPacket( MQTTLib.ControlPacket.Type.PINGREQ ) )
		  
		  // Set a delayed call for timeout
		  Xojo.Core.Timer.CallLater( Self.pControlPacketTimeToLive * 1000, AddressOf Self.HandlePINGTimedOut )
		  
		  System.DebugLog CurrentMethodName
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub ProcessCONNACK(inOptions As MQTTLib.OptionsCONNACK)
		  //-- Process the received CONNACK control packet
		  
		  If MQTTLib.VerboseMode Then System.DebugLog CurrentMethodName
		  
		  // Is the connection accepted?
		  If inOptions.ReturnCode = MQTTLib.OptionsCONNACK.kReturnCodeConnectionAccepted Then
		    // We are connected to the MQTT broker
		    pConnected = True
		    
		    // Arm the keep alive timer
		    Self.pKeepAliveTimer.Mode = Xojo.Core.Timer.Modes.Single
		    If MQTTLib.VerboseMode Then System.DebugLog CurrentMethodName + ": Broker connected"
		    
		    RaiseEvent BrokerConnected( inOptions.SessionPresentFlag )
		    
		  Else
		    // The connection has been refused by the broker
		    // It also means that the broker closed the connection
		    // But it cant't hurt to close on our side
		    If MQTTLib.VerboseMode Then System.DebugLog CurrentMethodName+  ": BrokerConnection rejected with code #" _
		    + Str( inOptions.ReturnCode ) + "."
		    
		    Self.pRawConnection.Close
		    RaiseEvent BrokerConnectionRejected( inOptions.ReturnCode )
		    
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub ProcessPINGRESP()
		  // Remove the PINGRESP timeout timer
		  
		  If MQTTLib.VerboseMode Then System.DebugLog CurrentMethodName
		  
		  Xojo.Core.Timer.CancelCall( WeakAddressOf Self.HandlePINGTimedOut )
		  
		  RaiseEvent ReceivedPINGRESP
		  
		  // rearm the keep alive timer
		  Self.pKeepAliveTimer.Mode = Xojo.Core.Timer.Modes.Single
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub ProcessProtocolError(inMethodName As String, inMessage As String, inError As MQTTLib.Error)
		  // An error means the connection has to be closed
		  Self.Disconnect
		  
		  // In verbose mode, all errors are logged
		  If MQTTLib.VerboseMode Then _
		  System.DebugLog inMethodName + ": " + inMessage + " *-* (#" + Str( Integer( inError ) ) + ")." 
		  
		  RaiseEvent Error( inMessage, inError )
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub ProcessPUBACK(inPUBACKData As MQTTLib.OptionsPUBACK)
		  //-- Process a PUBACK packet
		  
		  // Get the packet id
		  Dim thePacketID As UInt16 = inPUBACKData.PacketID
		  
		  If MQTTLib.VerboseMode Then System.DebugLog CurrentMethodName + ": Received a PUBACK with packetID #" + Str( thePacketID )
		  
		  // Check for zero packetID
		  If thePacketID = 0 Then
		    Self.ProcessProtocolError( CurrentMethodName, "A PUBACK's packetID can't be zero.", MQTTLib.Error.InvalidPacketID )
		    Return
		    
		  End If
		  
		  // Remove the original packet and timeout time from the unconfirmed control packet dictionaries
		  Self.RemovePacketAwaitingReply( thePacketID )
		  
		  RaiseEvent ReceivedPUBACK( thePacketID )
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub ProcessPUBCOMP(inPUBCOMPData As MQTTLib.OptionsPUBCOMP)
		  //-- Process a PUBCOMP packet
		  
		  // Get the packet id
		  Dim thePacketID As UInt16 = inPUBCOMPData.PacketID
		  
		  If MQTTLib.VerboseMode Then System.DebugLog CurrentMethodName + ": Received a PUBCOMP with packetID #" + Str( thePacketID )
		  
		  // Check for zero packetID
		  If thePacketID = 0 Then
		    Self.ProcessProtocolError( CurrentMethodName, "A PUBCOMP's packetID can't be zero.", MQTTLib.Error.InvalidPacketID )
		    Return
		    
		  End If
		  
		  // We should have a message with the same packet id in store.
		  If Not Self.pPacketsAwaitingReply.HasKey( thePacketID ) Then
		    Self.ProcessProtocolError( CurrentMethodName, "Unknown packet ID " + Str( thePacketID ) + " for PUBCOMP message.", MQTTLib.Error.UnknownPacketID )
		    Return
		    
		  End If
		  
		  // Get the stored message
		  Dim theStoredPacket As MQTTLib.ControlPacket = Self.pPacketsAwaitingReply.Value( thePacketID )
		  
		  // Check it's of the expected type
		  If theStoredPacket.Type <> MQTTLib.ControlPacket.Type.PUBREL Then
		    Self.ProcessProtocolError( CurrentMethodName, "The packet ID " + Str( thePacketID ) + " should be a PUBREL message but there is a " _
		    + theStoredPacket.TypeString + " instead.", MQTTLib.Error.UnexpectedResponseType )
		    Return
		    
		  End If
		  
		  // Remove the original packet and timeout time from the unconfirmed control packet dictionaries
		  Self.RemovePacketAwaitingReply( thePacketID )
		  
		  RaiseEvent ReceivedPUBCOMP( thePacketID )
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub ProcessPUBLISH(inPUBLISHData As MQTTLib.OptionsPUBLISH)
		  //-- Process a PUBLISH control packet
		  
		  Dim thePacketID As UInt16 = inPUBLISHData.PacketID
		  
		  If MQTTLib.VerboseMode Then
		    System.DebugLog CurrentMethodName + " PUBLISH received." + EndOfLine _
		    + "PacketID: " + Str( thePacketID ) _
		    + "Topic: " + inPUBLISHData.TopicName + EndOfLine _
		    + "Message: " + inPUBLISHData.Message
		    
		  End If
		  
		  RaiseEvent ReceivedPUBLISH( inPUBLISHData )
		  
		  // Handling the response depending of the QoS
		  
		  Select Case inPUBLISHData.QoSLevel
		    
		  Case MQTTLib.QoS.AtMostOnceDelivery // QoS = 0
		    // Nothing more to do here
		    Return
		    
		  Case MQTTLib.QoS.AtLeastOnceDelivery // QoS = 1
		    // Just send a PUBACK
		    Self.SendControlPacket New MQTTLib.ControlPacket( MQTTLib.ControlPacket.Type.PUBACK, New MQTTLib.OptionsPUBACK( thePacketID ) )
		    
		  Case MQTTLib.Qos.ExactlyOnceDelivery // QoS = 2
		    // Send a PUBREC
		    Dim thePUBREC As MQTTLib.ControlPacket = New MQTTLib.ControlPacket( MQTTLib.ControlPacket.Type.PUBREC, New MQTTLib.OptionsPUBREC( thePacketID ) )
		    Self.SendControlPacket thePUBREC
		    
		    // Store the control packet for time out purpose
		    Self.StorePacketAwaitingReply( thePacketID, thePUBREC )
		    
		  End Select
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub ProcessPUBREC(inPUBRECData As MQTTLib.OptionsPUBREC)
		  //-- Process a PUBREC packet.
		  // it is sent by the broker after receiving a PUBLISH message with QoS = 2 (Exactly once delivery)
		  
		  // Get the packet id
		  Dim thePacketID As UInt16 = inPUBRECData.PacketID
		  
		  // Log a message if needed
		  If MQTTLib.VerboseMode Then System.DebugLog CurrentMethodName + ": Received a PUBREC with packetID #" + Str( thePacketID )
		  
		  // --- Checking the packet validity ---
		  
		  // Check for zero packetID
		  If thePacketID = 0 Then
		    Self.ProcessProtocolError( CurrentMethodName, "A PUBREC's packetID can't be zero.", MQTTLib.Error.InvalidPacketID )
		    Return
		    
		  End If
		  
		  // We should have a message with the same packet id in store.
		  If Not Self.pPacketsAwaitingReply.HasKey( thePacketID ) Then
		    Self.ProcessProtocolError( CurrentMethodName, "Unknown packet ID " + Str( thePacketID ) + " for PUBREC message.", MQTTLib.Error.UnknownPacketID )
		    Return
		    
		  End If
		  
		  // Get the stored message
		  Dim theStoredPacket As MQTTLib.ControlPacket = Self.pPacketsAwaitingReply.Value( thePacketID )
		  
		  // Check it's the expected type
		  
		  If theStoredPacket.Type <> MQTTLib.ControlPacket.Type.PUBLISH Then
		    Self.ProcessProtocolError( CurrentMethodName, "The packet ID " + Str( thePacketID ) + " should be a PUBLISH message but there is a " _
		    + theStoredPacket.TypeString + " instead.", MQTTLib.Error.UnexpectedResponseType )
		    Return
		    
		  End If
		  
		  // --- Clear to process the PUBREC ---
		  
		  // Clear the dictionaries of this packet ID
		  Self.RemovePacketAwaitingReply( thePacketID )
		  
		  // give the subclass the control
		  RaiseEvent ReceivedPUBREC( thePacketID )
		  
		  // A PUBREC must be replied with a PUBREL
		  Dim thePUBREL As New MQTTLib.ControlPacket( MQTTLib.ControlPacket.Type.PUBREL, New MQTTLib.OptionsPUBREL( thePacketID ) )
		  Self.SendControlPacket thePUBREL
		  Self.StorePacketAwaitingReply( thePacketID, thePUBREL )
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub ProcessPUBREL(inPUBRELData As MQTTLib.OptionsPUBREL)
		  //-- Process a PUBREL packet.
		  // it is sent by the broker after receiving a PUBREC message when QoS = 2 (Exactly once delivery)
		  
		  // Get the packet id
		  Dim thePacketID As UInt16 = inPUBRELData.PacketID
		  
		  // Log a message if needed
		  If MQTTLib.VerboseMode Then System.DebugLog CurrentMethodName + ": Received a PUBREL with packetID #" + Str( thePacketID )
		  
		  // --- Checking the packet validity ---
		  
		  // Check for zero packetID
		  If thePacketID = 0 Then
		    Self.ProcessProtocolError( CurrentMethodName, "A PUBREL's packetID can't be zero.", MQTTLib.Error.InvalidPacketID )
		    Return
		    
		  End If
		  
		  // We should have a message with the same packet id in store.
		  If Not Self.pPacketsAwaitingReply.HasKey( thePacketID ) Then
		    Self.ProcessProtocolError( CurrentMethodName, "Unknown packet ID " + Str( thePacketID ) + " for PUBREL message.", MQTTLib.Error.UnknownPacketID )
		    Return
		    
		  End If
		  
		  // Get the stored message
		  Dim theStoredPacket As MQTTLib.ControlPacket = Self.pPacketsAwaitingReply.Value( thePacketID )
		  
		  // Check it's the expected type
		  
		  If theStoredPacket.Type <> MQTTLib.ControlPacket.Type.PUBREC Then
		    Self.ProcessProtocolError( CurrentMethodName, "The packet ID " + Str( thePacketID ) + " should be a PUBREC message but there is a " _
		    + theStoredPacket.TypeString + " instead.", MQTTLib.Error.UnexpectedResponseType )
		    Return
		    
		  End If
		  
		  // --- Clear to process the PUBREC ---
		  
		  // Clear the dictionaries of this packet ID
		  Self.RemovePacketAwaitingReply( thePacketID )
		  
		  // give the subclass the control
		  RaiseEvent ReceivedPUBREL( thePacketID )
		  
		  // A PUBREL must be replied with a PUBCOMP
		  Dim thePUBCOMP As New MQTTLib.ControlPacket( MQTTLib.ControlPacket.Type.PUBCOMP, New MQTTLib.OptionsPUBCOMP( thePacketID ) )
		  Self.SendControlPacket thePUBCOMP
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub ProcessSUBACK(inSUBACKData As MQTTLib.OptionsSUBACK)
		  //-- Process a PUBACK packet
		  
		  // Get the packet id
		  Dim thePacketID As UInt16 = inSUBACKData.PacketID
		  
		  If MQTTLib.VerboseMode Then System.DebugLog CurrentMethodName + ": Received a SUBACK with packetID #" + Str( thePacketID )
		  
		  // Check for zero packetID
		  If thePacketID = 0 Then
		    Self.ProcessProtocolError( CurrentMethodName, "A SUBACK's packetID can't be zero.", MQTTLib.Error.InvalidPacketID )
		    Return
		    
		  End If
		  
		  // Remove the original packet and timeout time from the unconfirmed control packet dictionaries
		  Self.RemovePacketAwaitingReply(thePacketID)
		  
		  RaiseEvent ReceivedSUBACK( inSUBACKData )
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub ProcessUNSUBACK(inUNSUBACKData As MQTTLib.OptionsUNSUBACK)
		  //-- Process a UNSUBACK packet
		  
		  // Get the packet id
		  Dim thePacketID As UInt16 = inUNSUBACKData.PacketID
		  
		  If MQTTLib.VerboseMode Then System.DebugLog CurrentMethodName + ": Received an UNSUBACK with packetID #" + Str( thePacketID )
		  
		  // Check for zero packetID
		  If thePacketID = 0 Then
		    Self.ProcessProtocolError( CurrentMethodName, "A UNSUBACK's packetID can't be zero.", MQTTLib.Error.InvalidPacketID )
		    Return
		    
		  End If
		  
		  // Remove the original packet and timeout time from the unconfirmed control packet dictionaries
		  Self.RemovePacketAwaitingReply( thePacketID )
		  
		  RaiseEvent ReceivedUNSUBACK( thePacketID )
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Publish(inOptions As MQTTLib.OptionsPUBLISH)
		  //-- Send a PUBLISH control packet
		  
		  If MQTTLib.VerboseMode Then System.DebugLog CurrentMethodName
		  
		  // Pre conditions
		  If inOptions Is Nil Then _
		  Raise New zd.EasyNilObjectException( CurrentMethodName, "inOptions can't be nil." )
		  
		  // If there is no packetID assigned (ie = 0 ), then set a new one
		  If inOptions.PacketID = 0 Then inOptions.PacketID = Self.NewPacketID
		  
		  // Create and send the control packet
		  Dim thePacket As New MQTTLib.ControlPacket( MQTTLib.ControlPacket.Type.PUBLISH, inOptions )
		  Self.SendControlPacket thePacket
		  
		  If inOptions.QoSLevel <> MQTTLib.QoS.AtMostOnceDelivery Then
		    // Store the packet for timeout purpose
		    Self.StorePacketAwaitingReply( inOptions.PacketID, thePacket )
		    
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub RemovePacketAwaitingReply(inPacketID As UInt16)
		  If Self.pPacketsAwaitingReply.HasKey( inPacketID ) Then Self.pPacketsAwaitingReply.Remove( inPacketID )
		  If Self.pPacketsAwaitingReplyTimeout.HasKey( inPacketID ) Then Self.pPacketsAwaitingReplyTimeout.Remove( inPacketID )
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub SendControlPacket(inControlPacket As MQTTLib.ControlPacket)
		  //-- Send the control packet to the broker through the raw connection
		  
		  If Self.pConnected Or _
		    ( inControlPacket.Type = MQTTLib.ControlPacket.Type.CONNECT And Not ( Self.pRawConnection Is Nil ) ) Then
		    
		    // Send the control packet
		    Self.pRawConnection.SendControlPacket inControlPacket
		    
		    // Reset the keep alive timer
		    If Not( Self.pKeepAliveTimer Is Nil ) Then 
		      Self.pKeepAliveTimer.Mode = Xojo.Core.Timer.Modes.Off
		      Self.pKeepAliveTimer.Mode = Xojo.Core.Timer.Modes.Single
		      
		    End If
		    
		  Else // There is no connection
		    Dim theMessage As String = "There is no raw connection to send the packet."
		    System.DebugLog CurrentMethodName + ": " + theMessage
		    Self.ProcessProtocolError( CurrentMethodName, theMessage, MQTTLib.Error.NotConnected )
		    
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub SendPUBACK(inPacketID As UInt16)
		  //-- Send a PUBACK packet to the broker
		  
		  If MQTTLib.VerboseMode Then System.DebugLog CurrentMethodName
		  
		  // Check for zero packetID
		  If inPacketID <> 0 Then
		    // Build and send the PUBACK Control packet
		    Self.SendControlPacket New ControlPacket( MQTTLib.ControlPacket.Type.PUBACK, New MQTTLib.OptionsPUBACK( inPacketID ) ) 
		    
		  Else
		    Me.Disconnect
		    Raise New MQTTLib.ProtocolException( CurrentMethodName, "A packetID can't be zero.", MQTTLib.Error.InvalidPacketID )
		    
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Setup(inSocketAdapter As MQTTLib.SocketAdapter, inConnectionSetup As MQTTLib.OptionsCONNECT)
		  
		  If MQTTLib.VerboseMode Then System.DebugLog CurrentMethodName
		  
		  // Create the periodic check timer and wire it
		  Self.pPeriodicCheckTimer = New Timer
		  AddHandler Self.pPeriodicCheckTimer.Action, WeakAddressOf Self.HandlePeriodicCheck
		  
		  // Store the connection setup
		  Self.pConnectionSetup = inConnectionSetup
		  
		  // Create the raw connection
		  Self.pRawConnection = New MQTTLib.RawConnection( inSocketAdapter )
		  
		  // Wire its events
		  AddHandler Self.pRawConnection.Connected, WeakAddressOf Self.HandleRawConnectionConnected
		  AddHandler Self.pRawConnection.ControlPacketReceived, WeakAddressOf Self.HandleRawConnectionControlPacketReceived
		  AddHandler Self.pRawConnection.Error, WeakAddressOf Self.HandleRawConnectionError
		  
		  // Set the keep alive timer's period
		  Self.pKeepAliveTimer.Period = inConnectionSetup.KeepAlive * 1000
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub StorePacketAwaitingReply(inPacketID As UInt16, inControlPacket As MQTTLib.ControlPacket)
		  
		  Self.pPacketsAwaitingReply.Value( inPacketID ) = inControlPacket
		  Self.pPacketsAwaitingReplyTimeout.Value( inPacketID ) = Microseconds + Self.pControlPacketTimeToLive * 1000000
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Subscribe(inOptions As MQTTLib.OptionsSUBSCRIBE)
		  // Subscribe to list of topics with a requested QoS
		  
		  If MQTTLib.VerboseMode Then System.DebugLog CurrentMethodName
		  
		  // Check the packet ID
		  If inOptions.PacketID = 0 Then inOptions.PacketID = Self.NewPacketID
		  
		  If MQTTLib.VerboseMode Then
		    Dim theParts() As String
		    theParts.Append CurrentMethodName + ": "
		    theParts.Append "PacketID: " + Str( inOptions.PacketID )
		    
		    Dim theCount As Integer = inOptions.Count
		    theParts.Append "TopicCount: " + Str( theCount )
		    
		    For i As Integer = 1 To theCount
		      Dim theTopic As MQTTLib.Topic = inOptions.Topic( i )
		      theParts.Append " * " + theTopic.Name + " (" + MQTTLib.QoSToString( theTopic.RequestedQoS ) + ")"
		      
		    Next
		    
		    System.DebugLog Join( theParts, EndOfLine )
		    
		  End If
		  
		  Dim thePacket As New MQTTLib.ControlPacket( MQTTLib.ControlPacket.Type.SUBSCRIBE, inOptions )
		  Self.SendControlPacket( thePacket )
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Unsubscribe(inOptions As MQTTLib.OptionsUNSUBSCRIBE)
		  //-- Unsubscribe from the topics listed in inOptions
		  
		  If MQTTLib.VerboseMode Then System.DebugLog CurrentMethodName
		  
		  // inOptions can't be nil
		  If inOptions Is Nil Then Raise New zd.EasyNilObjectException( CurrentMethodName, "inOptions can't be Nil." )
		  
		  // Check for the packetID validity
		  If inOptions.PacketID = 0 Then inOptions.PacketID = Self.NewPacketID
		  
		  // Generate the control packet and send it
		  Dim thePacket As New MQTTLib.ControlPacket( MQTTLib.ControlPacket.Type.SUBSCRIBE, inOptions )
		  Self.SendControlPacket thePacket
		  
		  // Store the packet with its ID for the SUBACK reply
		  Self.StorePacketAwaitingReply( inOptions.PacketID, thePacket )
		End Sub
	#tag EndMethod


	#tag Hook, Flags = &h0
		Event BrokerConnected(inSessionPresentFlag As Boolean)
	#tag EndHook

	#tag Hook, Flags = &h0
		Event BrokerConnectionRejected(inErrorCode As Integer)
	#tag EndHook

	#tag Hook, Flags = &h0
		Event Error(inMessage As String, inError As MQTTLib.Error)
	#tag EndHook

	#tag Hook, Flags = &h0
		Event ReceivedPINGRESP()
	#tag EndHook

	#tag Hook, Flags = &h0
		Event ReceivedPUBACK(inPacketID As UInt16)
	#tag EndHook

	#tag Hook, Flags = &h0
		Event ReceivedPUBCOMP(inPacketID As UInt16)
	#tag EndHook

	#tag Hook, Flags = &h0
		Event ReceivedPUBLISH(inPublish As MQTTLib.OptionsPUBLISH)
	#tag EndHook

	#tag Hook, Flags = &h0
		Event ReceivedPUBREC(inPacketID As UInt16)
	#tag EndHook

	#tag Hook, Flags = &h0
		Event ReceivedPUBREL(inPacketID As UInt16)
	#tag EndHook

	#tag Hook, Flags = &h0
		Event ReceivedSUBACK(inSUBACKData As MQTTLib.OptionsSUBACK)
	#tag EndHook

	#tag Hook, Flags = &h0
		Event ReceivedUNSUBACK(inPacketID As UInt16)
	#tag EndHook


	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  //-- Return True is the socket adapter is connected and the broker accepted the MQQT connection
			  
			  Return Self.pConnected
			End Get
		#tag EndGetter
		Connected As Boolean
	#tag EndComputedProperty

	#tag Property, Flags = &h21
		Private pConnected As Boolean
	#tag EndProperty

	#tag Property, Flags = &h21
		Private pConnectionSetup As MQTTLib.OptionsCONNECT
	#tag EndProperty

	#tag Property, Flags = &h21
		Private pControlPacketTimeToLive As Integer = 10
	#tag EndProperty

	#tag Property, Flags = &h21
		Private pKeepAliveTimer As Xojo.Core.Timer
	#tag EndProperty

	#tag Property, Flags = &h21
		#tag Note
			Used by the 'NewPacketID()' method to keep a track of the generated IDs
		#tag EndNote
		Private pPacketIDCounter As UInt16
	#tag EndProperty

	#tag Property, Flags = &h21
		#tag Note
			This dictionary stores the latest packet sent. The key is the packetID.
		#tag EndNote
		Private pPacketsAwaitingReply As Xojo.Core.Dictionary
	#tag EndProperty

	#tag Property, Flags = &h21
		#tag Note
			This dictionary stores the timeout time of the latest packet sent. The key Is the packetID.
		#tag EndNote
		Private pPacketsAwaitingReplyTimeout As Xojo.Core.Dictionary
	#tag EndProperty

	#tag Property, Flags = &h21
		Private pPeriodicCheckTimer As Timer
	#tag EndProperty

	#tag Property, Flags = &h21
		Private pRawConnection As MQTTLib.RawConnection
	#tag EndProperty


	#tag Constant, Name = kCONNECTDictionaryKey, Type = String, Dynamic = False, Default = \"CONNECT", Scope = Private
	#tag EndConstant

	#tag Constant, Name = kSentPingDictionaryKey, Type = String, Dynamic = False, Default = \"PINGREQ", Scope = Private
	#tag EndConstant


	#tag ViewBehavior
		#tag ViewProperty
			Name="Connected"
			Group="Behavior"
			Type="Boolean"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Index"
			Visible=true
			Group="ID"
			InitialValue="-2147483648"
			Type="Integer"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Left"
			Visible=true
			Group="Position"
			InitialValue="0"
			Type="Integer"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Name"
			Visible=true
			Group="ID"
			Type="String"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Super"
			Visible=true
			Group="ID"
			Type="String"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Top"
			Visible=true
			Group="Position"
			InitialValue="0"
			Type="Integer"
		#tag EndViewProperty
	#tag EndViewBehavior
End Class
#tag EndClass
