package ht.rpc
{
//	import ht.errors.ErrorResources;
//	import ht.errors.HtError;
//	import ht.math.HTMath;
	
	import mx.core.UIComponent;
	import mx.managers.CursorManager;
	import mx.messaging.messages.IMessage;
	import mx.rpc.AbstractOperation;
	import mx.rpc.AsyncToken;
	import mx.rpc.Fault;
	import mx.rpc.IResponder;
	import mx.rpc.Responder;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.utils.ObjectUtil;
	/**
	 * 批量远程调用类，功能：批量调用服务器端函数，示例：<br/>
	 * var rpc:BatRemoteObject=new BatRemoteObject;<br/>
	 * <br/>
	 * rpc.onResult=onResult1;<br/>
	 * rpc.addCaller("GetMachineTypeList");<br/>
	 * <br/><br/>
	 * rpc.onResult=onResult2;<br/>
	 * rpc.addCaller("GetValueTypeList",1);<br/>
	 * <br/>
	 * rpc.commit();<br/>
	 * <br/>
	 * @author cjy
	 *
	 */	
	public class DSRemoteObject extends HtRemoteObject
	{
		/**
		 * DS全部请求完成的处理函数, 以一个commit()为单位提交的, commit()后会被清除<br />
		 * 注意：<br />
		 * 1、如果是由数据缓冲池（FXGlobalModel）的TIMER来 commit()的，应该不允许设置该属性，<br />
		 * 2、如果是由其他对象自已 commit()的可以使用该属性<br />
		 */	
		public var onAllResult:Function;
		
		/**
		 * DS全部请求失败的处理函数, 以一个commit()为单位提交的, commit()后会被清除<br />
		 * 注意：<br />
		 * 1、如果是由数据缓冲池（FXGlobalModel）的TIMER来 commit()的，应该不允许设置该属性，<br />
		 * 2、如果是由其他对象自已 commit()的可以使用该属性<br />
		 */	
		public var onAllFault:Function = onDefaultFault;
		
		/**
		 * 构造函数<br />
		 * @param destination 网关的终点
		 * @param source 远端接口
		 * @param debug 是否连接调试服务器（调试模式）
		 * @param showBusyCursor 是否显示鼠标忙指针
		 *
		 */		
		public function DSRemoteObject(destination:String=null, source:String=null, debug:Boolean=false, showBusyCursor:Boolean=false)
		{
			super(destination, source, debug, showBusyCursor);
			//批处理一般不需要错误处理，该项设为空
			super.onFault = onDefaultFault;
		}

		
		/**
		 * 此函数功能 ：为远程调用列表，增加一个调用
		 * @param foo 方法名
		 * @param args 参数列表
		 *
		 */		
		[Deprecated("已经是不推荐的方法, 请用HTGlobal.currModel.rpc.addDSCaller")]
		public function addCaller(foo:String, ...args):void
		{
			var n:uint = args.length;
			var callObject:Object = {};
			var callParams:Array = [];

			for (var i:uint = 0; i < n; i++)
				callParams.push(args[i]);

			if (currentDomain == null)
				currentDomain = HtRemoteObject.DOMAIN;

			callObject.domain = currentDomain;
			callObject.foo = foo;
			callObject.params = callParams;
			_callerList.push(callObject);

			// ids 中承载了处理函数和用户自定义ids，在 onDSResultParser onFaultParser 中解析和处理
			var idsWapper : Object = {};
			idsWapper.onFaultCB = this.onFault;
			idsWapper.onResultCB = this.onResult;
			idsWapper.ids = this.ids;
			//idsWapper.progress = progress;
			_callerResponderList.push(idsWapper);
			
			this.onFault = onDefaultFault;
			this.onResult = null;
			currentDomain = DOMAIN;
		}

		/**
		 * 提交远程调用到服务器
		 *
		 */	
		[Deprecated("已经是不推荐的方法, HTGlobal.currModel.rpc会自动commit()")]	
		public function commit():void
		{
			if (_callerList.length == 0)
				return;
			r.source = HtRemoteObject.SYS_INFO_INTERFACE;
			var operation:AbstractOperation = r.getOperation("callDS");
			var call:AsyncToken = operation.send(_callerList.concat(), clientInfo);
			_callNumber++;

			call.ids = _callerResponderList.concat();
			call.progress = progress;
			call.onAllResult = onAllResult;
			call.onAllFault = onAllFault;
			call.addResponder(new mx.rpc.Responder(onBatResultParser, onBatFaultParser) as IResponder);

			//清除已发送的调用与回调
			_callerResponderList = [];
			_callerList = [];

			clearClientInfo();
			
			this.onAllFault = null;
			this.onAllResult = null;
		}

		/**
		 * DS的，远程调用列表
		 */		
		protected var _callerList:Array=[];
		/**
		 * DS的，回调者列表
		 */		
		protected var _callerResponderList:Array=[];
		
		/**
		 * 处理服务器返回的数据，如果正确，则调用'数据返回回调'，错误则调用'错误处理回调'
		 * @param evt 成功事件
		 *
		 */		
		private function onBatResultParser(e:ResultEvent):void
		{
			try
			{
				CursorManager.removeBusyCursor();

				_callNumber--;

				// 删除进度条对象
				if (null != e.token.progress)
				{
					var progress : UIComponent = e.token.progress as UIComponent;
					e.token.progress = null;
					if (null != progress && null != progress.parent && progress.parent.contains(progress))
						progress.parent.removeChild(progress);
				}
				var tmpOnAllResult:Function = e.token.onAllResult;
				var idsWapperList : Array = e.token.ids as Array;
				var resultList : Array = e.result as Array;
				var token : Array = e.token.message.body[0] as Array;

				//折分开服务器返回的结果列表，和回调列表，回调列表应与结果列表的个数一致
				if (resultList && idsWapperList)
				{
					if (resultList.length != idsWapperList.length)
					{
						var formatFault:Fault = new Fault("3000", "服务器返回格式有误");
						var formatErrorEvent:FaultEvent = new FaultEvent("HT", false, true, formatFault, e.token);
						//HtError.LogErrorEvent(formatErrorEvent);
						dispatchEvent(new RpcEvent(RpcEvent.RPC_ERROR, formatErrorEvent));
						return;
					}
				}
				else
				{
					var formatFault2:Fault = new Fault("3000", "服务器返回 格式有误");
					var formatErrorEvent2:FaultEvent = new FaultEvent("HT", false, true, formatFault2, e.token);
					//throw new Error("服务器返回格式有误2");//HtError.LogErrorEvent(formatErrorEvent2);
					dispatchEvent(new RpcEvent(RpcEvent.RPC_ERROR, formatErrorEvent2));
					return;
				}


				for (var i:uint=0;i<resultList.length;i++)
				{
					var newToken:AsyncToken = new AsyncToken(ObjectUtil.copy(e.message) as IMessage);
					var dataEvent:ResultEvent = new ResultEvent("HT", false, true, [resultList[i]], newToken);
					dataEvent.token.ids = idsWapperList[i];
					dataEvent.token.message.body = [token[i]];
					
					//分发给回调处理函数
					onDSDefaultResult(dataEvent);
				}

				if (null != tmpOnAllResult)
					tmpOnAllResult();
			}
			catch (err:Error)
			{
				//HTMath.formatErrMsg(this, "onBatResultParser", err);
				dispatchEvent(new RpcEvent(RpcEvent.RPC_ERROR, err));
				//throw err;//ht.errors.HtError.showError(err);
			}
		}	
		
		/**
		 * DS批量请求的错误处理，供系统自动调用
		 * @param e
		 * 
		 */		
		private function onBatFaultParser(e:FaultEvent):void
		{
			try
			{
				CursorManager.removeBusyCursor();
				hideProgressBar(e);
				_callNumber--;
				
				var tmpOnAllFault:Function = e.token.onAllFault;
				
				if (null !=tmpOnAllFault)
					tmpOnAllFault(e);
				else
					onDefaultFault(e);
			}
			catch (err:Error)
			{
				//HTMath.formatErrMsg(this, "onBatFaultParser", err);
				dispatchEvent(new RpcEvent(RpcEvent.RPC_ERROR, err));
				//throw err;//ht.errors.HtError.showError(err);
			}
		}
		
		
	}
}
