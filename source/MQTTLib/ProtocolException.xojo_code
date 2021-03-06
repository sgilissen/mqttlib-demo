#tag Class
Protected Class ProtocolException
Inherits zd.EasyException
	#tag Method, Flags = &h21
		Private Sub Constructor(inMethodName As String, inMessage As String, inErrorCode As Integer = -1)
		  // Just for deactivation of this constructor signature
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor(inMethodName As String, inMessage As String, inError As MQTTLib.Error)
		  // Calling the overridden superclass constructor.
		  Super.Constructor( inMethodName, inMessage )
		  
		  Self.pProtocolException = inError
		End Sub
	#tag EndMethod


	#tag Property, Flags = &h21
		Private pProtocolException As MQTTLib.Error
	#tag EndProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  Return Self.pProtocolException
			End Get
		#tag EndGetter
		ProtocolError As MQTTLib.Error
	#tag EndComputedProperty


	#tag ViewBehavior
		#tag ViewProperty
			Name="ErrorNumber"
			Group="Behavior"
			InitialValue="0"
			Type="Integer"
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
			Name="Message"
			Group="Behavior"
			Type="String"
			EditorType="MultiLineEditor"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Name"
			Visible=true
			Group="ID"
			Type="String"
		#tag EndViewProperty
		#tag ViewProperty
			Name="ProtocolError"
			Group="Behavior"
			Type="MQTTLib.Error"
			EditorType="Enum"
			#tag EnumValues
				"0 - NoError"
				"1 - Unknown"
				"2 - CantResolveAddress"
				"3 - InvalidPort"
				"4 - SelfDisconnection"
				"5 - TimedOut"
				"6 - LostConnection"
				"7 - SocketInvalidState"
				"8 - OutOfMemory"
				"9 - AddressInUse"
				"10 - MalformedFixedHeader"
				"11 - UnsupportedControlPacketType"
				"12 - ControlPacketNeedsData"
				"13 - ControlPacketDoesntNeedData"
				"14 - RemainingLengthExceedsMaximum"
				"15 - CONNACKParsingError"
				"16 - SUBACKParsingError"
				"17 - SocketAdapterNotConnected"
				"18 - InvalidFixedHeaderFlags"
				"19 - InvalidPacketID"
				"20 - PINGTimedOut"
				"21 - NotConnected"
				"22 - UnknownPacketID"
				"23 - UnexpectedResponseType"
			#tag EndEnumValues
		#tag EndViewProperty
		#tag ViewProperty
			Name="Reason"
			Group="Behavior"
			Type="Text"
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
