#tag Class
Protected Class OptionsSUBACK
Implements ControlPacketOptions
	#tag Method, Flags = &h0
		Sub AppendReturnCode(inReturnCode As MQTTLib.OptionsSUBACK.ReturnCodes)
		  pReturnCodes.Append inReturnCode
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function GetFixedHeaderFlagBits() As UInt8
		  Return &b0000
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function GetRawData() As String
		  // Return the binary data
		  Dim theParts() As String
		  
		  theParts.Append MQTTLib.GetUInt16BinaryString( Self.PacketID )
		  
		  For Each theCode As MQTTLib.OptionsSUBACK.ReturnCodes In pReturnCodes
		    theParts.Append ChrB( Integer( theCode ) )
		    
		  Next
		  
		  Return Join( theParts, "" )
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub ParseFixedHeaderFlagBits(inFlags As UInt8)
		  //-- Check if the flags are valid and raise an exception if they aren't.
		  
		  If inFlags <> &b0000 Then
		    Raise New MQTTLib.ProtocolException( CurrentMethodName, Self.kInvalidFlagBitsMessage, MQTTLib.Error.InvalidFixedHeaderFlags )
		    
		  Else
		    Return
		    
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub ParseRawData(inData As MemoryBlock)
		  // Parsing the PacketID
		  
		  //  --- Validate the data ---
		  
		  // Checking for Nil
		  If inData Is Nil Then Raise New zd.EasyNilObjectException( CurrentMethodName, "Can't parse Nil data." )
		  
		  Dim theLastOffset As Integer = inData.Size - 1
		  
		  // Checking for minimum size
		  If theLastOffset < 2 Then Raise New MQTTLib.ProtocolException( CurrentMethodName, "Not enough data to parse.", _
		  MQTTLib.Error.SUBACKParsingError )
		  
		  // --- Parsing the data ---
		  
		  // Extract the packet ID
		  PacketID = inData.Int16Value( 0 ) 
		  
		  // And the return code(s)
		  For i As Integer = 2 To theLastOffset
		    Dim theCodeUInt8 As UInt8 = inData.UInt8Value( i )
		    Dim theCode As MQTTLib.OptionsSUBACK.ReturnCodes
		    
		    Select Case theCodeUInt8
		      
		    Case Integer( MQTTLib.OptionsSUBACK.ReturnCodes.SuccessMaxQoSAtMostOnce )
		      theCode = MQTTLib.OptionsSUBACK.ReturnCodes.SuccessMaxQoSAtMostOnce
		      
		    Case Integer( MQTTLib.OptionsSUBACK.ReturnCodes.SuccessMaxQoSAtLeastOnce )
		      theCode = MQTTLib.OptionsSUBACK.ReturnCodes.SuccessMaxQoSAtLeastOnce
		      
		    Case Integer( MQTTLib.OptionsSUBACK.ReturnCodes.SuccessMaxQoSExactlyOnce )
		      theCode = MQTTLib.OptionsSUBACK.ReturnCodes.SuccessMaxQoSExactlyOnce
		      
		    Case Integer( MQTTLib.OptionsSUBACK.ReturnCodes.Failure )
		      theCode = MQTTLib.OptionsSUBACK.ReturnCodes.Failure
		      
		    Else
		      Raise New MQTTLib.ProtocolException( CurrentMethodName, "Invalid return code in the data: " + Str( theCodeUInt8 ), _
		      MQTTLib.Error.SUBACKParsingError )
		      
		    End Select
		    
		    pReturnCodes.Append theCode
		    
		  Next
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function ReturnCode(inIndex As Integer) As MQTTLib.OptionsSUBACK.ReturnCodes
		  //-- Return the return code for inIndex
		  
		  If inIndex < 0 Or inIndex > Self.pReturnCodes.UBound Then
		    // inIndex is out of bounds so raise a well documented exception
		    Raise New zd.EasyOutOfBoundsException( CurrentMethodName, _
		    "inIndex " + Str( inIndex ) + " is out of the bounds for pReturnCodes (0-" + Str( Self.pReturnCodes.Ubound ) + ")." )
		    
		  Else
		    // Get and return the value
		    Return Self.pReturnCodes( inIndex )
		    
		  End If
		End Function
	#tag EndMethod


	#tag Property, Flags = &h0
		PacketID As UInt16
	#tag EndProperty

	#tag Property, Flags = &h21
		Private pReturnCodes() As MQTTLib.OptionsSUBACK.ReturnCodes
	#tag EndProperty


	#tag Constant, Name = kInvalidFlagBitsMessage, Type = String, Dynamic = False, Default = \"The flag bits for SUBACK packet must be &b0000", Scope = Public
	#tag EndConstant


	#tag Enum, Name = ReturnCodes, Type = Integer, Flags = &h0
		SuccessMaxQoSAtMostOnce = &h00
		  SuccessMaxQoSAtLeastOnce = &h01
		  SuccessMaxQoSExactlyOnce = &h02
		Failure = &h80
	#tag EndEnum


	#tag ViewBehavior
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
			Name="PacketID"
			Group="Behavior"
			Type="UInt16"
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
