using System;
using System.Collections.Generic;
using System.Text;
using System.Collections;
using FluorineFx.Messaging;
using FluorineFx;
using log4net;

namespace OBDServiceLib.include
{
    /// <summary>
    /// HT错误异常类，用于抛异常和记录日志，接口: LogException(...)
    /// 请在取外层的函数中使用，内层请用 throw new Exception(...);
    /// </summary>
    public class HtException : MessageException
    {
        /// <summary>
        /// 构造函数，请在取外层的函数中使用，内层请用throw new Exception(...);
        /// </summary>
        public HtException(): base()
        {}

        /// <summary>
        /// 构造函数，请在取外层的函数中使用，内层请用throw new Exception(...);
        /// </summary>
        /// <param name="message">错误消息描述</param>
        public HtException(string message) : base(message)
        {}

        /// <summary>
        /// 构造函数，请在取外层的函数中使用，内层请用throw new Exception(...);
        /// </summary>
        /// <param name="message">错误消息描述</param>
        /// <param name="inner">捕获的Exception对象</param>
        public HtException(string message, Exception inner) : base(message, inner)
        {}

        /// <summary>
        /// 构造函数，请在取外层的函数中使用，内层请用throw new Exception(...);
        /// </summary>
        /// <param name="inner">捕获的Exception对象</param>
        public HtException(Exception inner) : base(inner)
        {}

        /// <summary>
        /// 构造函数，请在取外层的函数中使用，内层请用throw new Exception(...);
        /// </summary>
        /// <param name="message">错误消息描述</param>
        /// <param name="tmpObject">错误包 对象，用于发送到客户端</param>
        public HtException(string message, ASObject tmpObject) : base(tmpObject, message)
        {}

        /// <summary>
        /// 构造函数，请在取外层的函数中使用，内层请用throw new Exception(...);
        /// </summary>
        /// <param name="message">错误消息描述</param>
        /// <param name="inner">捕获的Exception对象</param>
        /// <param name="tmpObject">错误包 对象，用于发送到客户端</param>
        public HtException(string message, Exception inner, ASObject tmpObject) : base(tmpObject, message, inner)
        {}

        /// <summary>
        /// 记录日志，在实例化HtException后使用(内部调用)
        /// </summary>
        private void RwLog()
        {
            var s = new StringBuilder();
            IDictionaryEnumerator en = ExtendedData.GetEnumerator();

            while (en.MoveNext())
            {
                s.AppendLine(" Key::" + en.Key + "\n Value:: " + en.Value + "");
            }
            LogHelper.LogError("WS Exception : code::" + FaultCode + "  message::" + Message + "  source::" + Source + "\n" + s, this);
            LogHelper.LogError("\n>>>>>>>>>>>>>>>>>>>>>>>>>>>>> [end]\r\n");
        }



        /// <summary>
        /// 生成一个新的HtException对象
        /// </summary>
        /// <param name="code">错误码</param>
        /// <param name="message">错误消息描述</param>
        /// <returns>一个新的HtException对象</returns>
        public static HtException LogException(int code, string message)
        {
            var o = GetExceptionObjcet(code, message);
            var ex = new HtException(message,  o);
            ex.RwLog();
            return ex;
        }


        /// <summary>
        /// 根据捕获的Exception对象生成一个新的HtException对象
        /// </summary>
        /// <param name="code">错误码</param>
        /// <param name="message">错误消息描述</param>
        /// <param name="inner">捕获的Exception对象</param>
        /// <returns>一个新的HtException对象</returns>
        public static HtException LogException(int code, string message, Exception inner)
        {
            var o = GetExceptionObjcet(code, message, inner);
            var ex = new HtException(message, inner, o);
            ex.RwLog();
            return ex;
        }

        /// <summary>
        /// 生成一个新的错误包 对象
        /// </summary>
        /// <param name="code">错误码</param>
        /// <param name="what">错误消息描述</param>
        /// <returns>错误包 对象</returns>
        private static ASObject GetExceptionObjcet(int code, string what)
        {
            var tmpobject = new ASObject();
            tmpobject["code"] = code;
            tmpobject["what"] = what;
            return tmpobject;
        }

        /// <summary>
        /// 根据捕获的Exception对象生成一个新的错误包 对象
        /// </summary>
        /// <param name="code">错误码</param>
        /// <param name="what">错误消息描述</param>
        /// <param name="ex">捕获的Exception对象</param>
        /// <returns>错误包 对象</returns>
        private static ASObject GetExceptionObjcet(int code, string what, Exception ex)
        {
            var tmpobject = new ASObject();
            tmpobject["code"] = code;
            tmpobject["what"] = what;
            tmpobject["ex"] = ex;
            return tmpobject;
        }
    }
}
