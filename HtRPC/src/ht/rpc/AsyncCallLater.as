package ht.rpc
{
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	/**
	 * 提供了一个方法, 用于异步调度机制。
	 * @author cjy
	 * 
	 */	
	public class AsyncCallLater
	{
		static public function createCaller(method:Function, args:Array=null, delay:Number=300):void
		{
			new AsyncCallLater(method, args, delay);
		}
		
	    public function AsyncCallLater(method:Function, args:Array, delay:Number)
	    {
	        super();
	        _method = method;
	        _args = args;
	        _timer = new Timer(delay, 1);
	        _timer.addEventListener(TimerEvent.TIMER, timerEventHandler);
	        _timer.start();
	    }
	
	    //--------------------------------------------------------------------------
	    //
	    // Private Methods
	    //
	    //--------------------------------------------------------------------------
	
	    private function timerEventHandler(event:TimerEvent):void
	    {
	    	try
	    	{
		        _timer.stop();
		        _timer.removeEventListener(TimerEvent.TIMER, timerEventHandler);
		        // This call may throw so do not put code after it
		        _method.apply(null, _args);
			}
			catch (err:Error)
			{
				//HTMath.formatErrMsg(this, "timerEventHandler", err);
				//HtError.LogError(err);
				trace("AsyncCallLater::timerEventHandler error");
			}
	    }
	
	    //--------------------------------------------------------------------------
	    //
	    // Variables
	    //
	    //--------------------------------------------------------------------------
	
	    private var _method:Function;
	    private var _args:Array;
	    private var _timer:Timer;

	}
}