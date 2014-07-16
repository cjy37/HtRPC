package ht.model.vo
{
	

	public class FXConfig extends Object
	{
		/**
		 * 网关的终点，基本通讯参数
		 */
		static public var NET_DESTINATION:String = "fluorine";
		static public var PHP_DESTINATION:String = "zend";
		
		/**
		 * 调试标志 
		 */		
		static public var IS_DEBUG:Boolean = false;
		/**
		 * 调试时使用链接地址 
		 */	
		static public var SERVER_URL:String = "";
		
		static public var BASE_SERVER_URL:String = "";
		
		static public var CURR_DESTINATION:String = FXConfig.NET_DESTINATION;
		
		static public var frameRate:int = 24;
		
		public function FXConfig()
		{
			super();
		}
		
		/**
		 * @private
		 * @return 
		 * 
		 */		
		public function toString():String
		{
			return "FXConfig";
		}
		/**
		 * @private
		 * @return 
		 * 
		 */	
		public function valueOf():String
		{
			return "FXConfig";
		}
		
	}
}