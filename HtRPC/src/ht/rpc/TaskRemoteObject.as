package ht.rpc
{
	import flash.events.Event;
	
	import ht.model.vo.FXTask;
	
	import mx.rpc.events.ResultEvent;

	/**
	 * 功能：<br />
	 *<br />
	 * 1、取状态文本<br />
	 * 2、取状态码<br />
	 * 3、取结束以后的数据<br />
	 * 4、发送StatusChanged事件(状态码发生变化时发送)<br />
	 * 6、发送TaskUpdate事件（每次通讯后发送）<br />
	 * 7、可设置通讯的时间间隔<br />
	 * 8、可取消任务<br />
	 * 9、可设置任务ID<br />
	 *<br />
	 * @author cjy
	 *
	 */	
	public class TaskRemoteObject extends HtRemoteObject
	{
		/**
		 * 状态改变
		 */		
		static public const EVENT_STATUS_CHANGED:String="StatusChanged";
		/**
		 * 任务更新
		 */		
		static public const EVENT_TASK_UPDATE:String="TaskUpdate";
		
		//-------------------------------------------
		// 任务运行状态码
		//-------------------------------------------
		
		/**
		 *  任务未开始
		 */		
		static public var RUN_STATUS_NOT_RUN:Number = 0;
		
		/**
		 * 任务正在运行
		 */		
		static public var RUN_STATUS_RUNNING:Number = 1;
		
		/**
		 * 任务已结束
		 */		
		static public var RUN_STATUS_OVER:Number = 2;
		
		/**
		 * 任务已取消
		 */		
		static public var RUN_STATUS_CANCEL:Number = 3;
		
		/**
		 * 
		 * @return 
		 * 
		 */		
		public function get isRunning():Boolean
		{
			if (null == _task)
				return false;
			return _task.isRunning;
		}
		
		/**
		 * 
		 * @return 
		 * 
		 */		
		public function get isOK():Boolean
		{
			if (null == _task)
				return false;
			return _task.isOK;
		}
		
		/**
		 * 
		 * @return 
		 * 
		 */		
		public function get isFailed():Boolean
		{
			if (null == _task)
				return false;
			return _task.isFailed;
		}

		
		/**
		 * 获取任务对象
		 * @return 
		 * 
		 */		
		public function get task():FXTask
		{
			return _task;
		}
		
		public function set task(val:FXTask):void
		{
			if (null == val)
				return;
			_task = val;
		}
		
		/**
		 * 取消任务
		 * 
		 */		
		public function cancel():void
		{
			if (null != _task)
				_task.cancel();
		}
		/**
		 * 构造函数
		 * @param destination	网关的终点
		 * @param source   远端接口
		 * @param debug	 是否连接调试服务器（调试模式）
		 * @param showBusyCursor	是否显示鼠标忙指针
		 *
		 */
		public function TaskRemoteObject(destination:String=null, source:String=null, debug:Boolean=false, showBusyCursor:Boolean=false)
		{
			super(destination, source, debug, showBusyCursor);
			onResult = default_resultHandler;
		}
		
		protected var _task:FXTask;
		/**
		 * 获得任务结果
		 * @return  任务结果
		 *
		 */		
		public function getTaskResult():Object
		{ 
			if (null == _task)
				return null;
				
			return _task.taskResult; 
		}

		/**
		 * 获得当前状态描述
		 * @return 当前状态描述
		 *
		 */		
		public function getStatusDescription():String
		{
			if (null == _task)
				return "";
				
			return _task.description;
		}

		/**
		 * 设置任务ID，任务ID为NULL才允许设置
		 * @param pid
		 *
		 */		
		public function setPID(pid:String,label:String = ""):void
		{ 
			if (null ==pid)
			{
				cancel();
				return;
			}
				
			_task = new FXTask(label, pid);
			_task.addEventListener(FXTask.EVENT_STATUS_CHANGED,onChanged,false,0,true);
			_task.addEventListener(FXTask.EVENT_TASK_UPDATE,onUpdate,false,0,true);
		}
		
		private function onChanged(e:Event):void
		{
			//状态变化，发送事件
			dispatchEvent(new Event(TaskRemoteObject.EVENT_STATUS_CHANGED));
		}
		
		private function onUpdate(e:Event):void
		{
			//状态变化，发送事件
			dispatchEvent(new Event(TaskRemoteObject.EVENT_TASK_UPDATE));
		}
		
		/**
		 * 设置通讯的时间间隔(秒)
		 * @param delay
		 *
		 */		
		public function setDelay(delay:Number):void
		{ 
			_delay=delay;
			
			if (null != _task)
				_task.delay = _delay;
		}


		private var _delay:Number=2;

		/**
		 * 调用成功处理函数
		 * @param event
		 *
		 */
		private function default_resultHandler(event:ResultEvent):void
		{
			try
			{
				if (null == event.result)
					return;
					
				setPID(String(event.result));
			}
			catch (err:Error)
			{
				//HTMath.formatErrMsg(this, "default_resultHandler", err);
				dispatchEvent(new RpcEvent(RpcEvent.RPC_ERROR, err));
				//throw err;//HtError.LogError(err);
			}
		}
	}//end class
}
