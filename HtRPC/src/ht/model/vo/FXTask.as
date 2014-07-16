package ht.model.vo
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	import ht.rpc.DSHandler;
	import ht.rpc.WSRemoteObject;
	
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	
	[Bindable]
	/**
	 * 任务对象，如果有了任务ID（PID），则任务就启动<br />
	 * 可以从外面取到任务的信息:<br />
	 * 1、取状态文本<br />
	 * 2、取状态码<br />
	 * 3、取结束以后的数据<br />
	 * 4、发送StatusChanged事件(状态码发生变化时发送)<br />
	 * 6、发送TaskUpdate事件（每次通讯后发送）<br />
	 * 7、可设置通讯的时间间隔<br />
	 * 8、可取消任务<br />
	 * 9、可设置任务ID<br />
	 * @author cjy
	 * 
	 */	
	public class FXTask extends EventDispatcher
	{
		//-------------------------------------------
		// 事件码
		//-------------------------------------------
		
		/**
		 * 状态改变事件
		 */		
		static public const EVENT_STATUS_CHANGED:String = "StatusChanged";
		
		/**
		 * 任务更新事件
		 */		
		static public const EVENT_TASK_UPDATE:String = "TaskUpdate";
		
		/**
		 * 任务完成事件
		 */		
		static public const EVENT_TASK_COMPLETE:String = "TaskComplete";
		
		/**
		 * 任务错误事件
		 */		
		static public const EVENT_TASK_ERROR:String = "TaskError";
		
		/**
		 * 任务取消事件
		 */		
		static public const EVENT_TASK_CANCEL:String = "TaskCancel";
		

		private var _timer:Timer;
		private var _rpc:WSRemoteObject;
		/**
		 * 
		 * @return 
		 * 
		 */		
		public function get isRunning():Boolean
		{
			return _taskStatus == TASK_PENDING || _taskStatus == TASK_RUNNING || _taskStatus == TASK_PREPARING;
		}
		
		/**
		 * 
		 * @return 
		 * 
		 */		
		public function get isOK():Boolean
		{
			return _taskStatus == TASK_FINISH;
		}
		
		/**
		 * 
		 * @return 
		 * 
		 */		
		public function get isFailed():Boolean
		{
			return _taskStatus == TASK_TIMEOUT || _taskStatus == TASK_FAILED || _taskStatus == TASK_CANCLE;
		}
		
		
		/**
		 * 向DS取任务状态后，本函数可以根据状态码取到任务运行状态的描述
		 * @param val 状态码
		 * @return 状态的描述
		 * 
		 */		
		public function get description():String
		{
			switch (_taskStatus)
			{
				case TASK_FAILED:
					_desc = "任务结束，处理失败";
					break;
				case TASK_FINISH:
					_desc = "任务执行成功";
					break;
				case TASK_PENDING:
					_desc = "任务正在准备";
					break;
				case TASK_CANCLE:
					_desc = "任务已取消";
					break;
				case TASK_RUNNING:
					_desc = "任务正在运行";
					break;
				case TASK_TIMEOUT:
					_desc = "任务结束，已超时";
					break;
				case TASK_PREPARING:
					_desc = "任务正在准备";
					break;
				default:
					_desc = "未知任务状态";
					break;
			}
			return _desc;
		}
		public function set description(value:String):void
		{
			_desc = value;
		}
		
		/**
		 * DS传回来的任务ID（PID）
		 * @return 
		 * 
		 */		
		public function get taskId():String
		{
			return _taskId;
		}
		
		public function set taskId(val:String):void
		{
			if (null == val)
				return;
			this._taskStatus = TASK_PREPARING;
			_taskId = val;
		}
		
		/**
		 * 设置通讯间隔
		 * @return 
		 * 
		 */		
		public function get delay():Number
		{
			return _delay;
		}
		public function set delay(val:Number):void
		{
			if (isNaN(val))
				return;
			_delay = val;
		}
		
		/**
		 * 该任务类型的描述，创建本类时给出
		 * @return 描述的文本
		 * 
		 */		 
		public function get label():String
		{
			return _label;
		}
		public function set label(val:String):void
		{
			_label = val;
		}
		
		/**
		 * 向DS取任务状态后，的结果集
		 * @return 
		 * 
		 */		
		public function get taskResult():Object
		{
			return _taskResult;
		}
		
		/**
		 * 初始化函数
		 * 
		 */
		public function FXTask(strLabel:String, PID:String, numDelay:Number = 2, target:IEventDispatcher = null)
		{
			_timer = new Timer(3000);
			_rpc = new WSRemoteObject;
			super(target);
			
			taskId = PID;
			delay = numDelay;
			label = strLabel;
			
			_timer.addEventListener(TimerEvent.TIMER, onTimer, false, 0, true); //HTGlobal.addTimerListener(onTimer);
			//addEventListener(FXTask.EVENT_TASK_CANCEL, function (event:Event):void { _timer.removeEventListener(TimerEvent.TIMER, onTimer) } );
			//addEventListener(FXTask.EVENT_STATUS_CHANGED, function (event:Event):void { _timer.removeEventListener(TimerEvent.TIMER, onTimer) } );
		}
		
		public function cancel():void
		{
			_timer.removeEventListener(TimerEvent.TIMER, onTimer);
			_taskStatus = TASK_CANCLE;
			//完成，发送事件
			dispatchEvent(new Event(FXTask.EVENT_STATUS_CHANGED));
			dispatchEvent(new Event(FXTask.EVENT_TASK_CANCEL));
		}
		
		/**
		 * 调用DS接口以后，成功取到PID的处理函数，供外部使用
		 * @param event 事件
		 *
		 */
		public function onResultPID(event:ResultEvent):void
		{
			try
			{
				if (null == event.result)
					return;
					
				taskId = String(event.result);
			}
			catch (err:Error)
			{
				//HTMath.formatErrMsg(this, "onResultPID", err);
				//HtError.LogError(err);
			}
		}
		/**
		 * 该任务的任务ID（PID），创建本类时给出
		 */		
		protected var _taskId:String = "";
		
		/**
		 * 该任务类型的描述，创建本类时给出
		 */		
		protected var _label:String = "";
		
		/**
		 * 向DS取任务状态后，的状态码
		 */		
		protected var _taskStatus:Number = NaN;
		
		/**
		 * 向DS取任务状态后，的结果集
		 */		
		protected var _taskResult:Object;
		
		protected var _delay:Number = 2;
		private var _timerCount:Number = 0;
		//第1次必须执行所以默认为1
		private var _taskTimeCount:Number = 1;
		private var _isComplete:Boolean = false;

		public function get isComplete():Boolean
		{
			return _isComplete;
		}

		/**
		 * 定时器事件回调处理函数
		 * @param e
		 * 
		 */		
		protected function onTimer(e:Event):void
		{
			_timerCount ++;
			if (_timerCount < FXConfig.frameRate)
				return;
			_timerCount = 0;
			
			if (!isRunning)
			{
				cancel();
				return;
			}
			
			if (_taskId.length == 0)
				return;
			_taskTimeCount ++;	
			getTask();
			
		}
		
		/**
		 * 向DS获取任务
		 * 
		 */		
		protected function getTask():void
		{
			_rpc.onResult = onResultHandler;
			_rpc.onFault = onFaultHandler;
			_rpc.currentDomain = DSHandler.GetDataHandler;
			_rpc.addDSCaller("GetTaskResult", _taskId);
			_rpc.commit();
		}
		
		/**
		 * 获取任务成功处理
		 * @param e
		 * 
		 */		
		protected function onResultHandler(e:ResultEvent):void
		{
			if (_isComplete)
				return;
			if (null == e.result)
				return;
			
			if (e.result.hasOwnProperty("status"))
			{
				if (_taskStatus != Number(e.result.status))
				{
					_taskStatus = Number(e.result.status);
					//状态变化，发送事件
					dispatchEvent(new Event(FXTask.EVENT_STATUS_CHANGED));
				}
				_taskStatus = Number(e.result.status);
			}

			if (e.result.hasOwnProperty("result"))
				_taskResult = e.result.result;

			if (!isRunning)
			{
				if (_taskStatus == TASK_FINISH) //完成，发送事件
					dispatchEvent(new Event(FXTask.EVENT_TASK_COMPLETE));
				else //error，发送事件
					dispatchEvent(new Event(FXTask.EVENT_TASK_ERROR));
				//(HTGlobal.iindex as index).removeEventListener(Event.ENTER_FRAME, onTimer);
				_timer.removeEventListener(TimerEvent.TIMER, onTimer);
				_isComplete = true;
			}
			
			//通讯完成，发送事件
			dispatchEvent(new Event(FXTask.EVENT_TASK_UPDATE));
		}
		
		public function get errorMsg():String
		{
			return _errorMsg;
		}
		protected var _errorMsg:String = "查询任务状态失败...";
		/**
		 * 获取任务失败处理
		 * @param e
		 * 
		 */		
		protected function onFaultHandler(e:FaultEvent):void
		{
			_timer.removeEventListener(TimerEvent.TIMER, onTimer);
			_taskStatus = TASK_FAILED;
			var err:Error = new Error("获取任务状态失败，任务ID：" + _taskId, 7789);
			//HtError.LogError(err);
			//错误，发送事件
			dispatchEvent(new Event(FXTask.EVENT_TASK_ERROR));
			dispatchEvent(new Event(FXTask.EVENT_STATUS_CHANGED));
			
		}
		
		//-------------------------------------------
		// 任务状态码
		//-------------------------------------------
		
		/**
		 * 任务处理失败
		 */		 
		static private const TASK_FAILED:Number = 0;
		
		/**
		 * 任务已完成
		 */		
		static private const TASK_FINISH:Number = 1;
		
		/**
		 * 任务开始
		 */		
		static private const TASK_PENDING:Number = 2;
		
		/**
		 *  任务被取消
		 */		
		static private const TASK_CANCLE:Number = 3;
		
		/**
		 * 任务正在运行
		 */		
		static private const TASK_RUNNING:Number = 4;
		
		/**
		 * 任务已经超时
		 */		
		static private const TASK_TIMEOUT:Number = 5;
		
		/**
		 * PREPARING = 6;// 任务正在准备
		 */		
		static private const TASK_PREPARING:Number = 6;
		
		private var _desc:String = "";
	}
}