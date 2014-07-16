package ht.rpc
{
	import flash.events.Event;
	
	public class RpcEvent extends Event
	{
		static public const RPC_ERROR:String = "rpc_error";
		
		public var errorObject:Object = {};

		public function RpcEvent(type:String, errObj:Object, bubbles:Boolean=true, cancelable:Boolean=false)
		{
			errorObject = errObj;
			super(type, bubbles, cancelable);
		}
		
		override public function clone():Event
		{
			var e:Event = new RpcEvent(this.type, this.errorObject, this.bubbles, this.cancelable);
			return e;
		}
	}
}