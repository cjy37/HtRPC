package ht.rpc
{
	import flash.events.EventDispatcher;
	import flash.net.SharedObject;
	import flash.utils.ByteArray;
	
	import ht.model.vo.FXConfig;
	
	import mx.core.UIComponent;
	import mx.managers.CursorManager;
	import mx.rpc.AbstractOperation;
	import mx.rpc.AsyncToken;
	import mx.rpc.Fault;
	import mx.rpc.IResponder;
	import mx.rpc.events.AbstractEvent;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.rpc.remoting.mxml.RemoteObject;
	import mx.utils.ObjectUtil;

	/**
	 * 与服务器通讯的对象，负责FLASH与服务器的通讯
	 * @author cjy
	 *
	 */
	public class HtRemoteObject extends EventDispatcher
	{
		/**
		 * 远端接口：系统信息相关的接口，与WS批量通信/与DS通信时使用
		 */
		static public var SYS_INFO_INTERFACE:String = "OBDServiceLib.RemoteInterface.SysInfoInterface";
		
		static public var DESTINATION:String = "fluorine";
		/**
		 * 远程调用的类名，与DS通讯时使用
		 */
		static public const DOMAIN:String = "DSHandle";
		
		/**
		 * 远程调用成功处理函数，由视图设置
		 */
		public var onResult:Function = null;
		
		/**
		 * 远程调用失败处理函数<br/>
		 * 默认情况视图不用设置，由系统指定，<br/>
		 * 如果需要特殊处理：1、比如客户端不单单只显示错误信息时，2、不需要显示错误提示时<br/>
		 * 注：后台运行的程序一般不需要给用户提示错误时，请把本项设置为空，批处理类此处为空<br/>
		 */
		public var onFault:Function = HtRemoteObject.onFaultDefault;

		/**
		 * 当前远程调用的类名<br />
		 * 一般为HtRemoteObject.DOMAIN<br />
		 */
		public var currentDomain:String = HtRemoteObject.DOMAIN;
		
		/**
		 * 	object // client info<br />
		 *  {// 根据不同客户端的差异，设置不同的信息<br />
		 *  	string machineid;		// 机组ID，若不存在，则为“”<br />
		 *  	string dauid;			// 采集器ID，若不存在，则为“”<br />
		 *  	number hops;			// 数据跳转数，DAU上传的数据该值为0，每经过一级<br />
		 *  	// 服务器加1；WS提交的请求该值为-1;<br />
		 *  <br />
		 * 		// WS<br />
		 *  	string language<br />
		 *  	...<br />
		 *  <br />
		 * 		// DS<br />
		 *  	string IP<br />
		 *  	number type;	// 1：往复机采集器；2：风电采集器；3：旋转机械采集器<br />
		 *  	...<br />
		 *  }
		 *
		 */
		public var clientInfo:Object = {machineid:"", dauid:"", hops:-1, language:""};
		
		/**
		 * 用户自定义对象，在返回的事件中 event.token.ids 中可获取到
		 */
		public var ids:Object = null;
		

		/**
		 * 通讯过程中的进度条，在通讯结束后自动从parent移除，并删除此对象
		 */
		public var progress:UIComponent;

		/**
		 * 远程调用次数
		 * @return
		 *
		 */
		public function get callNumber():int
		{
			return _callNumber;
		}

		protected var r:RemoteObject;
		/**
		 * 构造函数
		 * @param destination    网关的终点
		 * @param source    远端接口
		 * @param debug    是否连接调试服务器（调试模式）
		 * @param showBusyCursor    是否显示鼠标忙指针
		 *
		 */
		public function HtRemoteObject(destination:String=null, source:String=null, debug:Boolean=false, showBusyCursor:Boolean=false)
		{
			if (destination == null)
				destination=FXConfig.NET_DESTINATION;
			if (source == null)
				source=HtRemoteObject.SYS_INFO_INTERFACE;

			r = new RemoteObject(destination);
			r.source=source;
			r.showBusyCursor=showBusyCursor; //鼠标指针忙
			if ((debug || FXConfig.IS_DEBUG) && FXConfig.SERVER_URL.length > 0)
			{
				r.endpoint=FXConfig.SERVER_URL; //指定服务器端点调试时使用
			}
		}
		
		/**
		 * 远程调用 WS Server 中的函数
		 * @param foo 远程函数名
		 * @param args 远程函数的参数列表...
		 *
		 */		 
		public function callWS(foo:String, ... args):void
		{

			if (foo.length == 0)
				throw new Error("foo can not be empty!");

			//getOperation(getLocalName(name)).send.apply(null, args);	

			var operation:AbstractOperation=r.getOperation(foo);
			var call:AsyncToken=operation.send.apply(null, args);

			_callNumber++;

			// ids 中承载了处理函数和用户自定义ids，在 onDSResultParser onFaultParser 中解析和处理
			var idsWapper:Object={};
			idsWapper.onFaultCB=this.onFault;
			idsWapper.onResultCB=this.onResult;
			idsWapper.ids=this.ids;
			idsWapper.progress=progress;
			call.ids=idsWapper;

			call.addResponder(new mx.rpc.Responder(onWSResultParser, onFaultParser)as IResponder);
			
			this.onFault = onDefaultFault;
			this.onResult = null;
			progress = null;
		}

		/**
		 * 远程调用 DS Server 中的函数<br />
		 *<br />
		 * 需要使用回调函数请设置：onResult, onFault<br />
		 *<br />
		 * @param foo    远程函数名
		 * @param args   远程函数的参数列表...
		 *
		 */
		public function callDS(foo:String, ... args):void
		{
			var n:uint = args.length;
			if (foo.length == 0)
				throw new Error("foo can not be empty!");
			if (currentDomain == null)
				currentDomain = DOMAIN;

			var callArray:Array = [];
			var callObject:Object = {};
			var callParams:Array = [];

			for (var i:uint = 0; i < n; i++)
				callParams.push(args[i]);

			callObject.domain = currentDomain;
			callObject.foo = foo;
			callObject.params = callParams;

			callArray.push(callObject);

			var operation:AbstractOperation = r.getOperation("callDS");

			var call:AsyncToken = operation.send(callArray, clientInfo);
			_callNumber ++;

			// ids 中承载了处理函数和用户自定义ids，在 onDSResultParser onFaultParser 中解析和处理
			var idsWapper:Object = {};
			idsWapper.onFaultCB = this.onFault;
			idsWapper.onResultCB = this.onResult;
			idsWapper.ids = this.ids;
			idsWapper.progress = progress;
			call.ids = idsWapper;

			call.addResponder(new mx.rpc.Responder(onDSResultParser, onFaultParser)as IResponder);

			clearClientInfo();
			
			this.onFault = onDefaultFault;
			this.onResult = null;
			currentDomain = DOMAIN;
			progress = null;
		}

		/**
		 * 远程通讯，失败处理函数,供视图直接使用
		 * @param e 事件
		 *
		 */
		static public function onFaultDefault(e:FaultEvent):void
		{
			CursorManager.removeBusyCursor();
			throw new Error(e.fault.faultString);//dispatchEvent(new RpcEvent(RpcEvent.RPC_ERROR, e))//HtError.showErrorEvent(e);
			
		}

		private var __callNumber:int=0;

		/**
		 * 远程调用次数 0:没有进行远程调用
		 */
		protected function get _callNumber():int
		{
			return __callNumber;
		}
		protected function set _callNumber(value:int):void
		{
			__callNumber = value;
		}


		/**
		 * 初始化客户信息
		 *
		 */
		protected function clearClientInfo():void
		{
			clientInfo={machineid:"", dauid:"", hops:-1, language:""};
		}


		protected function getByteResult(ret:Object):Object
		{
			if (null == ret)
				return null;
			
			if (ret is ByteArray)
				ret = (ret as ByteArray).readObject();
			
			return ret;
		}
		
		
		/**
		 * 处理服务器返回的数据，如果正确，则调用'数据返回回调'，错误则调用'错误处理回调'
		 * @param evt 成功事件
		 *
		 */
		protected function onWSDefaultResult(e:ResultEvent):void
		{
			try
			{
				var idsWapper:Object=e.token.ids;
				var errorRet:Object = e.result;
				
				
				
				hideProgressBar(e);
				CursorManager.removeBusyCursor();
				e.token.ids=idsWapper.ids;
				
				
				if (null != errorRet && 
						!(errorRet is ByteArray) && 
						errorRet.hasOwnProperty("code") && 
						errorRet.code != 0) 
				{
					var onFault:Function = idsWapper.onFaultCB as Function;
					var fault:Fault = new Fault(e.result.code,e.result.what);// "返回数据格式有误" + ObjectUtil.toString(e));
					var errorEvent:FaultEvent = new FaultEvent("fault", false, true, fault, e.token, e.token.message);
					errorEvent.token.ids = idsWapper.ids;
					errorEvent.fault.rootCause = e.result.RootCause;
					
					if (null != onFault)
						onFault(errorEvent);
					else
						dispatchEvent(new RpcEvent(RpcEvent.RPC_ERROR, errorEvent));//HtError.LogErrorEvent(errorEvent);
					//HtError.showErrorString(errorRet.what, "提示 [" + errorRet.code + "]");
				} else {
					
					var onResult:Function=idsWapper.onResultCB as Function;
					if (null != onResult)
					{
						var dataEvent:ResultEvent=new ResultEvent("result", false, true, e.result.ret, e.token, e.token.message);
						dataEvent.token.ids=idsWapper.ids;
						onResult(dataEvent);
						return ;
					}
					
					
//					var onResult:Function = idsWapper.onResultCB as Function;
//					if (null != onResult)
//						onResult(e);
				}
			}
			catch (err:Error)
			{
				//HTMath.formatErrMsg(this, "onWSDefaultResult", err);
				dispatchEvent(new RpcEvent(RpcEvent.RPC_ERROR, err));
				//throw err;//ht.errors.HtError.showError(err);
			}
		}


		/**
		 * 处理服务器返回的数据，如果正确，则调用'数据返回回调'，错误则调用'错误处理回调'
		 * @param evt 成功事件
		 *
		 */
		protected function onDSDefaultResult(e:ResultEvent):void
		{
			try
			{
				var idsWapper:Object=e.token.ids;

				// 删除进度条对象
				hideProgressBar(e);
				
				CursorManager.removeBusyCursor();
				var fault:Fault;
				var onFault:Function;
				var errorEvent:FaultEvent;
				if (e.result is Array)
				{
					if (e.result[0].code == 0)
					{ // 服务返回正确，调用返回回调函数
						var onResult:Function=idsWapper.onResultCB as Function;
						if (null != onResult)
						{
							var dataEvent:ResultEvent=new ResultEvent("result", false, true, e.result[0].ret, e.token, e.token.message);
							dataEvent.token.ids=idsWapper.ids;
							
							onResult(dataEvent);
							return ;
						}
					}
					else
					{
						var faultCode:int=Number(e.result[0].code);
						if (!faultCode)
							faultCode=9; //未知错误
						fault=new Fault(faultCode.toString(), e.result[0].what);
						errorEvent=new FaultEvent("fault", false, true, fault, e.token, e.token.message);
						errorEvent.token.ids=idsWapper.ids;
						errorEvent.fault.rootCause = e.result[0];

						onFault=idsWapper.onFaultCB as Function;
						if (null != onFault)
							onFault(errorEvent);
						else
							dispatchEvent(new RpcEvent(RpcEvent.RPC_ERROR, errorEvent));//HtError.LogErrorEvent(errorEvent);
					}
				}
				else
				{
					// construct event
					fault=new Fault("501", "返回数据格式有误" + ObjectUtil.toString(e));
					errorEvent=new FaultEvent("fault", false, true, fault, e.token, e.token.message);
					errorEvent.token.ids=idsWapper.ids;
					errorEvent.fault.rootCause = e.result[0];

					// send
					onFault=idsWapper.onFaultCB as Function;
					if (null != onFault)
						onFault(errorEvent);
					else
						dispatchEvent(new RpcEvent(RpcEvent.RPC_ERROR, errorEvent));//HtError.LogErrorEvent(errorEvent);
				}
			}
			catch (err:Error)
			{
				//HTMath.formatErrMsg(this, "onDSDefaultResult", err);
				dispatchEvent(new RpcEvent(RpcEvent.RPC_ERROR, err));
				//throw err;//ht.errors.HtError.showError(err);
			}
		}

		/**
		 * 如果服务器返回一个错误，则此函数被调用
		 * @param e
		 *
		 */
		protected function onDefaultFault(e:FaultEvent):void
		{
			try
			{
				CursorManager.removeBusyCursor();
				var idsWapper:Object;
				var onFault:Function;
				if (e.token.hasOwnProperty("ids"))
					idsWapper = e.token.ids;
				
				if (null != idsWapper && idsWapper.hasOwnProperty("onFaultCB"))
				{
					onFault=idsWapper.onFaultCB as Function;
					e.token.ids=idsWapper.ids;
				}
				
				if (null != onFault)
					//HTGlobal.callLater(onFault, [e]);
					onFault(e);
				else
					dispatchEvent(new RpcEvent(RpcEvent.RPC_ERROR, e));//HtError.showErrorEvent(e);
			}
			catch (err:Error)
			{
				//HTMath.formatErrMsg(this, "onDefaultFault", err);
				dispatchEvent(new RpcEvent(RpcEvent.RPC_ERROR, err));
				//throw err;//ht.errors.HtError.showError(err);
			}
		}


		
		/**
		 * 隐藏进度条
		 * @param e
		 * 
		 */		
		protected function hideProgressBar(e:AbstractEvent):void
		{
//			try
//			{
//				var progressBar:UIComponent;
//				if (null != e.token.progress)
//				{
//					progressBar = e.token.progress;
//				}
//				else if (null != e.token.ids && e.token.ids is UIComponent)
//				{
//					progressBar = e.token.ids;
//				}
//				else if (null != e.token.ids && null != e.token.ids.progress && e.token.ids.progress is UIComponent)
//				{
//					progressBar = e.token.ids.progress as UIComponent;
//				}
//				else
//				{
//					return;
//				}
//					
//				//弹出窗口式的
//				if (progressBar is GetTaskProgressBar)
//				{
//					HTGlobal.removePopupWindow(progressBar as MDIWindow);
//				}
//				else
//				{
//					//嵌入视图式的
//					if (null != progressBar && null != progressBar.parent && progressBar.parent.contains(progressBar))
//						progressBar.parent.removeChild(progressBar);
//				}
//			}
//			catch (err:Error)
//			{
//				HTMath.formatErrMsg(this, "hideProgressBar", err);
//				HtError.LogError(err);
//			}
		}
		
//		[Deprecated("已经是不推荐的方法")]
//		static public function getFault(e:FaultEvent):void
//		{
//			onFaultDefault(e);
//		}
//
//		/**
//		 * 远程通讯，返回正确的处理
//		 * @param e 事件
//		 *
//		 */
//		[Deprecated("已经是不推荐的方法")]
//		static public function getResult(e:ResultEvent):Object
//		{
//			return e.result[0].ret;
//		}


		/**
		 *
		 */
		//private var cookies:SharedObject;
		
		/**
		 * 处理服务器返回的数据，WS回调函数入口
		 * @param evt 成功事件
		 *
		 */
		private function onWSResultParser(e:ResultEvent):void
		{
			_callNumber--;
			onWSDefaultResult(e);
		}

		/**
		 * 处理服务器返回的数据，DS回调函数入口
		 * @param evt 成功事件
		 *
		 */
		private function onDSResultParser(e:ResultEvent):void
		{
			_callNumber--;
			onDSDefaultResult(e);
		}

		

		
				
		/**
		 * 如果服务器返回一个错误，则此函数被调用，回调函数入口
		 * @param e
		 *
		 */
		private function onFaultParser(e:FaultEvent):void
		{
			_callNumber--;
			hideProgressBar(e);
			onDefaultFault(e);
		}
	}
}
