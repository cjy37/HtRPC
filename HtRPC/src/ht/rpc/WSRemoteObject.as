package ht.rpc
{
	//import com.adobe.serialization.json.JSON;
	//import com.adobe.serialization.json.JSONDecoder;
	//import com.adobe.serialization.json.JSONEncoder;
	
	import flash.events.Event;
	
	import mx.core.UIComponent;
	import mx.managers.CursorManager;
	import mx.messaging.messages.AcknowledgeMessage;
	import mx.messaging.messages.IMessage;
	import mx.rpc.AbstractOperation;
	import mx.rpc.AsyncToken;
	import mx.rpc.Fault;
	import mx.rpc.IResponder;
	import mx.rpc.Responder;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
import ht.rpc.RpcEvent;

import mx.managers.CursorManager;
import mx.rpc.events.FaultEvent;

	
	/**
	 * <pre>
	 * 批量远程通讯接口类
	 *   建议所有请求都使用本类
	 *   数据缓冲池对象（FXGlobalModel）的rpc是本类的实例
	 * 
	 * 使用的方法：
	 * 	1、基于数据缓冲池访问DS：设置onFault; onResult; addDSCaller; 即可
	 * 	2、基于数据缓冲池访问WS：设置onFault; onResult; addCaller; 即可
	 * 	3、远程调用：如需要全部请求返回后进行回调处理，则设置 onAllResult; onAllFault; 
	 * 	   这时，调用 commit 后才会提交addDSCaller、addCaller的请求
	 * </pre> 
	 * @author cjy
	 *
	 */	
	public class WSRemoteObject extends HtRemoteObject
	{
		static public var EVENT_DS_LOSE:String = "DSLose";
		/**
		 * <pre>
		 * 默认的WS打包远程调用的错误处理函数,供外部使用<br>
		 * 本函数的功能为显示错误，及记录客户端LOG<br>
		 * 使用方法：
		 *   由具体的程序实例化WSRemoteObject后，指定该实例的onAllFault为本函数即可，
		 *   这可降低程序员在开发与RPC有关的功能时的代码量，相关约束请看onAllFault的说明
		 * </pre>
		 * @param e
		 * 
		 */		
		static public function defaultWSFaultHandler(e:FaultEvent):void
		{
			try
			{
				throw new Error(e.fault.faultString);//dispatchEvent(new RpcEvent(RpcEvent.RPC_ERROR, e));//ht.errors.HtError.showErrorEvent(e);
			}
			catch (err:Error)
			{
				//HTMath.formatErrMsg("HTGlobal", "defaultWSFaultHandler", err);
				
				//dispatchEvent(new RpcEvent(RpcEvent.RPC_ERROR, err));
				throw err;
				//HtError.LogError(err);
			}
		}
		
		
		/**
		 * <pre>
		 * WS全部请求完成的处理函数, 以一个commit()为单位提交的, commit()后会被清除
		 * 注意：
		 * 1、如果是由数据缓冲池（FXGlobalModel）的TIMER来 commit()的，应该不允许设置该属性，
		 * 2、如果是由其他对象自已 commit()的可以使用该属性
		 * </pre>
		 */		
		public var onAllResult:Function;
		
		/**
		 * <pre>
		 * WS全部请求失败的处理函数, 以一个commit()为单位提交的, commit()后会被清除
		 * 注意：
		 * 1、如果是由数据缓冲池（FXGlobalModel）的TIMER来 commit()的，应该不允许设置该属性，
		 * 2、如果是由其他对象自已 commit()的可以使用该属性
		 * </pre>
		 */		
		public var onAllFault:Function;
		
		public var isShowLog4Error:Boolean = true;
		
		/**
		 * 网络不畅时的失败重试次数
		 */	
		public function get numReSend():Number
		{
			return _numReSend;
		}
		
		public function get lastSendDate():Date
		{ return _lastSendDate; }
		
		private var _lastSendDate:Date = new Date;
		
		/**
		 * 构造函数
		 * @openErrorShow 是否出错时显式通知用户，
		 * 		为true时：不指定错误回调也显示错误(onAllFault除外)，
		 * 		为false时：不指定错误回调时将不显示，演示时需要关闭显式通知功能
		 * @param destination 网关的终点
		 * @param source 远端接口
		 * @param debug 是否连接调试服务器（调试模式）
		 * @param showBusyCursor 是否显示鼠标忙指针
		 *
		 */		
		public function WSRemoteObject(openErrorShow:Boolean = true, 
							destination:String = null, source:String = null, 
							debug:Boolean = false, showBusyCursor:Boolean = false)
		{
			super(destination, source, debug, showBusyCursor);
			
			//批处理一般不需要错误处理，该项设为空
			isShowLog4Error = openErrorShow;
			if (isShowLog4Error)
				super.onFault = onDefaultFault;
			else
				super.onFault = null;
		}

		/**
		 * <pre>
		 * 此函数功能 ：为WS的远程调用列表，增加一个调用
		 * 功能：
		 *  1、如果已有一模一样的调用，该函数则自动过滤重复的调用
		 *  2、调用该函数后，onFault、onResult 会重置为初始值，避免对后来的调用产生污染
		 *  3、该函数会把 成功回调(onResult), 失败回调(onFault), 回调标识(ids) 打包到一个调用中，
		 *     当数据返回时，可以根据这些回调参数来进行具体的处理
		 * 注：* 约束：在使用时，未初化完成的地方，如果参数不全，应限制调用
		 * </pre>
		 * @param className WS的类名，包括全路径
		 * @param methodName WS的className类中的函数名
		 * @param args WS的methodName指定的函数要求的参数
		 * 
		 */		 	
		public function addCaller(className:String,methodName:String, ...args):void
		{
			var n:uint = args.length;
			var callObject:Object={};
			var callParams:Array=[];

			for (var i:uint=0; i < n; i++)
				callParams.push(args[i]);

			callObject.className=className;
			callObject.methodName=methodName;
			callObject.params=callParams;
			_callerList.push(callObject);

			// ids 中承载了处理函数和用户自定义ids，在 onDSResultParser onFaultParser 中解析和处理
			var idsWapper : Object = {};
			idsWapper.onFaultCB = this.onFault;
			idsWapper.onResultCB = this.onResult;
			idsWapper.ids = this.ids;
			//idsWapper.progress = progress;
			_callerResponderList.push(idsWapper);
			
			if (isShowLog4Error)
				this.onFault = onDefaultFault;
			else
				this.onFault = null;
			this.onResult = null;
			ids = null;
		}

		/**
		 * <pre>
		 * 此函数功能 ：为DS的远程调用列表，增加一个调用
		 * 功能：
		 *  1、如果已有一模一样的调用，该函数则自动过滤重复的调用
		 *  2、调用该函数后，onFault、onResult 会重置为初始值，避免对后来的调用产生污染
		 *  3、该函数会把 成功回调(onResult), 失败回调(onFault), 回调标识(ids) 打包到一个调用中，
		 *     当数据返回时，可以根据这些回调参数来进行具体的处理
		 * 注：* 约束：在使用时，未初化完成的地方，如果参数不全，应限制调用
		 * </pre>
		 * @param foo DS方法名
		 * @param args DS方法的参数列表
		 *
		 */		
		public function addDSCaller(foo:String, ...args):void
		{
			//if (foo =="GetMpRTStatus")
			//	return;
			var n:uint = args.length;
			//一个标志是否允许添加调用，true时继续，false时已经存在（退出），默认是允许添加任意的远程调用，
			{
				var dsCallerTmpArgs:String = foo + "_";
				for (var i:uint = 0; i < n; i++)
				{
					var tmpParam:Object = args[i];
					if (tmpParam is Array)
					{
						tmpParam = (tmpParam as Array).join("_");
					}
					dsCallerTmpArgs = dsCallerTmpArgs + "_" + tmpParam;
				}
					

				if (dsCallerTmp.hasOwnProperty(dsCallerTmpArgs))
					return;
				dsCallerTmp[dsCallerTmpArgs] = true; 
			}
			
			var callObject:Object = {};
			var callParams:Array = [];

			for (var j:uint = 0; j < n; j++)
				callParams.push(args[j]);

			if (currentDomain == null)
				currentDomain = DOMAIN;

			callObject.domain = currentDomain;
			callObject.foo = foo;
			callObject.params = callParams;
			_dsCallerList.push(callObject);

			// ids 中承载了处理函数和用户自定义ids，在 onDSResultParser onFaultParser 中解析和处理
			var idsWapper:Object = {};
			idsWapper.onFaultCB = this.onFault;
			idsWapper.onResultCB = this.onResult;
			idsWapper.ids = this.ids;
			//idsWapper.progress = progress;
			_dsCallerResponderList.push(idsWapper);
			if (isShowLog4Error)
				this.onFault = onDefaultFault;
			else
				this.onFault = null;
			this.onResult = null;
			currentDomain = DOMAIN;
			ids = null;
		}
			

		/**
		 * <pre>
		 * 提交远程调用到WS服务器 
		 * 功能： 
		 * 	1、把所有的 _callerList 中的调用请求，打包到一个远程调用中，一次性的向服务器通讯 
		 *     ids 则是_callerResponderList 回调的列表，ids、onAllResult、onAllFault、progress等在回调处理时会得到处理 
		 *  2、添加 onAllResult、onAllFault、progress 到远程调用中， 
		 *     当有数据返回或失败后，系统自动调用用户指定的回调进行处理 
		 *  3、当打包的远程调用发送后，清空 _callerList、_callerResponderList  
		 *     重置 onAllResult、onAllFault为默认值，避免污染下次通讯 
		 * 注：如果是通过FXGlobalModel 的rpc 来commit，那么，应该避免设置onAllResult、onAllFault， 
		 *     因为，如果多个地方对他进行过设置，会多次的复写onAllResult、onAllFault， 
		 *     导致等到FXGlobalModel 的rpc 来commit的时候，已经被复写多次，这样就失去了他原有的意义 
		 * </pre>
		 */		
		public function commit():void
		{
			commitDS();
			
			if (_callerList.length == 0)
				return;
			r.source = HtRemoteObject.SYS_INFO_INTERFACE;
			var operation:AbstractOperation = r.getOperation("callWS");
			var call:AsyncToken=operation.send(_callerList.concat());
			_callNumber++;
			_numReSend = 1;
			call.ids = _callerResponderList.concat();
			call.onAllResult = onAllResult;
			call.onAllFault = onAllFault;
			call.progress = progress;
			call.addResponder(new mx.rpc.Responder(onBatResultParser, onBatFaultParser) as IResponder);

			//清除已发送的调用与回调
			_callerResponderList = [];
			_callerList = [];
			onAllResult = null;
			onAllFault = null;
			progress = null;
			dsCallerTmp = {};
			_lastSendDate = new Date;
		}
		
		public function get hasCaller():Boolean
		{
			return _dsCallerList.length >0 || _callerList.length > 0; 
		}
		
		public function disconnect():void
	    {
	    	_callNumber = 0;
	        r.disconnect();
	    }
    
		/**
		 * 网络不畅时的重试次数
		 */    	
		protected var _numReSend:Number = 1;
		
		/**
		 * <pre>
		 * WS的调用缓冲池，调用列表
		 * 当 commit 后会被清空
		 * </pre>
		 */		
		protected var _callerList:Array=[];
		
		/**
		 * <pre>
		 * WS的回调信息缓冲池，回调参数列表
		 * 当 commit 后会被清空
		 * </pre>
		 */		
		protected var _callerResponderList:Array=[];

		/**
		 * <pre>
		 * DS的调用缓冲池，调用列表
		 * 当 commitDS 后会被清空
		 * </pre>
		 */		
		protected var _dsCallerList:Array = [];
		
		/**
		 * <pre>
		 * DS的回调信息缓冲池，回调参数列表
		 * 当 commitDS 后会被清空</pre>
		 */		
		protected var _dsCallerResponderList:Array = [];


		/**
		 * <pre>
		 * 提交远程调用到DS服务器(由系统自动调用)，注意打包请求DS的远程调用等于调用WS的一个请求[callDS]
		 * 
		 * 功能：
		 * 	1、把所有的 _dsCallerList 中的调用请求，打包到一个远程调用中，一次性的向服务器通讯
		 *     ids 则是_dsCcallerResponderList 回调的列表，ids等在回调处理时会得到处理
		 *  2、当打包的远程调用发送后，清空 _dsCallerList、_dsCallerResponderList 
		 * 
		 *  注：commitDS 会被 commit 自动调用，想要commitDS生效，应调用 commit</pre>
		 */		
		protected function commitDS():void
		{
			if (_dsCallerList.length == 0)
				return;

			ids = _dsCallerResponderList.concat();
			onResult = onDSBatResultParser;
			onFault = onDSBatFaultParser;
			
			//打包加入WS的调用列表
			addCaller(HtRemoteObject.SYS_INFO_INTERFACE, "callDS", _dsCallerList.concat(), clientInfo);
			
			//清除已发送的调用与回调
			_dsCallerResponderList=[];
			_dsCallerList=[];
			clearClientInfo();
		}
		
	
		
		/**
		 * 网络不畅时重试
		 * @param e
		 * 
		 */		
		protected function reCommit(e:FaultEvent):void
		{

			r.source = HtRemoteObject.SYS_INFO_INTERFACE;
			
			var operation:AbstractOperation = r.getOperation("callWS");
			var tmpCallList:Array = e.token.message.body[0] as Array;
			var tmpids:Array = e.token.ids as Array;
			
			var call:AsyncToken = operation.send(tmpCallList.concat());
			call.ids = tmpids;
			call.onAllResult = e.token.onAllResult;
			call.onAllFault = e.token.onAllFault;
			call.progress = progress;
			call.addResponder(e.token.responders[0] as IResponder);
			
			_numReSend ++;
			progress = null;
			_lastSendDate = new Date;
		}
		
		
		/**
		 * <pre>
		 * 临时保存DS调用列表
		 * 用于把重复的远程调用排除在外
		 * commitDS后清空</pre>
		 */		
		private var dsCallerTmp:Object = {};
		
		
				
		/**
		 * <pre>
		 * WS处理服务器返回的数据，本函数由本类与本类的子类的实例自动调用，与外部无关
		 * 如果正确，则调用'数据返回回调'，错误则调用'错误处理回调'</pre>
		 * @param evt 通讯成功事件
		 *
		 */		
		private function onBatResultParser(e:ResultEvent):void
		{
			try
			{
				CursorManager.removeBusyCursor();
				hideProgressBar(e);
				_callNumber--;

				// 删除进度条对象
				if (null != e.token.progress)
				{
					var progress : UIComponent = e.token.progress as UIComponent;
					e.token.progress = null;
					if (null != progress && null != progress.parent && progress.parent.contains(progress))
						progress.parent.removeChild(progress);
				}

				var idsWapperList : Array = e.token.ids as Array;
				var resultList : Array = e.result as Array;
				var token : Array = e.token.message.body[0] as Array;
				
				var tmpOnAllResult:Function = e.token.onAllResult;
				
				//折分开服务器返回的结果列表，和回调列表，回调列表应与结果列表的个数一致
				if (resultList && idsWapperList)
				{
					if (resultList.length != idsWapperList.length)
					{
						throw new Error("服务器返回格式有误");//HtError.showErrorString("服务器返回格式有误","通讯错误");
						return;
					}
				}
				else
				{
					var errorRet:Object = e.result;
					if (errorRet.hasOwnProperty("code") && errorRet.code != 0)
						throw new Error(errorRet.what);//HtError.showErrorString(errorRet.what, "提示 [" + errorRet.code + "]");
					else
						throw new Error("服务器返回格式有误");//HtError.showErrorString("服务器返回格式有误","通讯错误");
					return;
				}
				
				for (var i:uint=0;i<resultList.length;i++)
				{	
					var message:IMessage = new AcknowledgeMessage;
					var newToken:AsyncToken = new AsyncToken(message as IMessage);
					var dataEvent:ResultEvent = new ResultEvent("result", false, true, resultList[i], newToken);
					
					dataEvent.token.ids = idsWapperList[i];
					dataEvent.token.message.body = [token[i]];
					//分发给回调处理函数
					//HTGlobal.callLater(onWSDefaultResult, [dataEvent]);
					onWSDefaultResult(dataEvent);
				}
				if (null != tmpOnAllResult)
					//HTGlobal.callLater(tmpOnAllResult, [e]);
					tmpOnAllResult(e);
			}
			catch (err:Error)
			{
				//HTMath.formatErrMsg(this, "onBatResultParser", err);
				dispatchEvent(new RpcEvent(RpcEvent.RPC_ERROR, err));
				//throw err;
				//HtError.LogError(err);
			}
		}
		
//		static protected var pross:GetTaskProgressBar;
		/**
		 * WS批量请求的错误处理，本函数由本类与本类的子类的实例自动调用，与外部无关
		 * @param e
		 * 
		 */		
		private function onBatFaultParser(e:FaultEvent):void
		{
			try
			{
				/*var tmpTrace:String = JSON.encode(e.token.message.body[0]);
				trace(tmpTrace);*/
				CursorManager.removeBusyCursor();
				hideProgressBar(e);
				//重试
				if (false && _numReSend <= 10)
				{
					if (isShowLog4Error)
					{
						var title:String = "正在与服务器通讯...重试第[" + _numReSend + "]次";
//						if (null == pross)
//						{
//							pross = HTGlobal.showProgressBar(title, null, true);
//						}
//						else
//						{
//							pross.title = title;
//							HTGlobal.iindex.addWindow(pross);
//						}
//						
//						progress = pross;
					}
					//延迟3秒重试
//					new AsyncCallLater(reCommit, [e], 3500);
					return;
				}
				else
				{
					_callNumber--;
					if (false && isShowLog4Error)
					{
						dispatchEvent(new Event(WSRemoteObject.EVENT_DS_LOSE));
						var err:Error = new Error;
						err.message = "与服务器通讯失败，已达到最大重试次数。\n请检查服务器程序是否启动/网络连接是否正常。";
						dispatchEvent(new RpcEvent(RpcEvent.RPC_ERROR, err));
						//throw err;//HtError.LogError(err);
					}
					
					
					var tmpOnAllFault:Function = e.token.onAllFault;
					if (null !=tmpOnAllFault)
						//HTGlobal.callLater(tmpOnAllFault, [e]);
						tmpOnAllFault(e);
					else
						dispatchEvent(new RpcEvent(RpcEvent.RPC_ERROR, e));
					return;
				}
				
			}
			catch (err:Error)
			{
				//HTMath.formatErrMsg(this, "onBatFaultParser", err);
				dispatchEvent(new RpcEvent(RpcEvent.RPC_ERROR, err));
				//throw err;
				//HtError.LogError(err);
			}
		}
		
		
		/**
		 * <pre>
		 * DS处理服务器返回的数据，
		 * 本函数由本类与本类的子类的实例自动调用，与外部无关
		 * 如果正确，则调用'数据返回回调'，错误则调用'错误处理回调'</pre>
		 * @param evt 成功事件
		 *
		 */		
		private function onDSBatResultParser(e:ResultEvent):void
		{
			try
			{
				CursorManager.removeBusyCursor();

				// 删除进度条对象
				hideProgressBar(e);

				var idsWapperList : Array = e.token.ids as Array;
				var resultList : Array = getByteResult(e.result) as Array;
				var token : Array = e.token.message.body[0].params[0] as Array;
				var tmpOnAllResult:Function = e.token.onAllResult;

				//在DS未启动的情况下会进入此分支
				if (resultList.length == 1)
				{
					var resultObject:Object = resultList[0];
					var DSErrorCode:Number = Number(resultObject.code);
					/* 
					// 在转发的DLL中，连接不上DS有四种情况：
					const uint32 HT_COMM_NO_ANSWER		= 0x1300;	// communication error, server no answer
					const uint32 HT_COMM_DATA_PARSE		= 0x1301;	// data parse failed when communication
					const uint32 HT_COMM_NOT_COMMIT		= 0x1302;	// call GetResult before the request is commit success
					const uint32 HT_COMM_PROTOCOL_ERROR	= 0x1303;	// protocol of the data error
					*/
					switch (DSErrorCode)
					{
						case 4864,4865,4865,4865:
						{
							var tmpFault:Fault = new Fault(resultObject.code + "" , resultObject.what + "");
							var DSErrorEvent:FaultEvent = new FaultEvent("HT", false, true, tmpFault, e.token, e.token.message);
							DSErrorEvent.fault.rootCause = resultList;
							dispatchEvent(new Event(WSRemoteObject.EVENT_DS_LOSE));
							dispatchEvent(new RpcEvent(RpcEvent.RPC_ERROR, DSErrorEvent));//HtError.LogErrorEvent(DSErrorEvent);
							return;
							break;
						}
						default:
							break;
					}
				}
				
				//折分开服务器返回的结果列表，和回调列表，
				//回调列表应该与结果列表的个数一致，不一致者，会进入此分支
				if (null != resultList && null != idsWapperList)
				{
					if (resultList.length != idsWapperList.length)
					{
						var formatFault:Fault = new Fault("3000", "服务器返回格式有误");
						var formatErrorEvent:FaultEvent = new FaultEvent("HT", false, true, formatFault, e.token, e.token.message);
						formatErrorEvent.fault.rootCause = resultList;
						dispatchEvent(new RpcEvent(RpcEvent.RPC_ERROR, formatErrorEvent));//HtError.LogErrorEvent(formatErrorEvent);
						return;
					}
				}
				else
				{
					var formatFault2:Fault = new Fault("3000", "服务器返回 格式有误");
					var formatErrorEvent2:FaultEvent = new FaultEvent("HT", false, true, formatFault2, e.token, e.token.message);
					formatErrorEvent2.fault.rootCause = resultList;
					dispatchEvent(new RpcEvent(RpcEvent.RPC_ERROR, formatErrorEvent2));//HtError.LogErrorEvent(formatErrorEvent2);
					return;
				}

				for (var i:uint=0;i<resultList.length;i++)
				{
					var message:IMessage = new AcknowledgeMessage;
					var newToken:AsyncToken = new AsyncToken(message as IMessage);
					var dataEvent:ResultEvent = new ResultEvent("HT", false, true, [resultList[i]], newToken);
					
					dataEvent.token.ids = idsWapperList[i];
					dataEvent.token.message.body = [token[i]];
					//onDSResultParser会把m_callNumber减一，所以这里先加一
					//分发给回调处理函数
//					HTGlobal.callLater(onDSDefaultResult,[dataEvent]);
					onDSDefaultResult(dataEvent);
				}
			}
			catch (err:Error)
			{
				//HTMath.formatErrMsg(this, "onDSBatResultParser", err);
				dispatchEvent(new RpcEvent(RpcEvent.RPC_ERROR, err));
				//throw err;
				//HtError.LogError(err);
			}
		}	
		/**
		 * DS批量请求的错误处理，本函数由本类与本类的子类的实例自动调用，与外部无关
		 * @param e
		 * 
		 */		
		private function onDSBatFaultParser(e:FaultEvent):void
		{
			try
			{
				CursorManager.removeBusyCursor();
				hideProgressBar(e);
				
				var tmpOnAllFault:Function = e.token.onAllFault;
				if (null !=tmpOnAllFault)
					tmpOnAllFault(e);
				else if (isShowLog4Error)
					onDefaultFault(e);
			}
			catch (err:Error)
			{
				//HTMath.formatErrMsg(this, "onDSBatFaultParser", err);
				dispatchEvent(new RpcEvent(RpcEvent.RPC_ERROR, err));
				//throw err;//HtError.LogError(err);
			}
		}

	}
}
