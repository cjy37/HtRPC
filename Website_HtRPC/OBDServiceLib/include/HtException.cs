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
    /// HT�����쳣�࣬�������쳣�ͼ�¼��־���ӿ�: LogException(...)
    /// ����ȡ���ĺ�����ʹ�ã��ڲ����� throw new Exception(...);
    /// </summary>
    public class HtException : MessageException
    {
        /// <summary>
        /// ���캯��������ȡ���ĺ�����ʹ�ã��ڲ�����throw new Exception(...);
        /// </summary>
        public HtException(): base()
        {}

        /// <summary>
        /// ���캯��������ȡ���ĺ�����ʹ�ã��ڲ�����throw new Exception(...);
        /// </summary>
        /// <param name="message">������Ϣ����</param>
        public HtException(string message) : base(message)
        {}

        /// <summary>
        /// ���캯��������ȡ���ĺ�����ʹ�ã��ڲ�����throw new Exception(...);
        /// </summary>
        /// <param name="message">������Ϣ����</param>
        /// <param name="inner">�����Exception����</param>
        public HtException(string message, Exception inner) : base(message, inner)
        {}

        /// <summary>
        /// ���캯��������ȡ���ĺ�����ʹ�ã��ڲ�����throw new Exception(...);
        /// </summary>
        /// <param name="inner">�����Exception����</param>
        public HtException(Exception inner) : base(inner)
        {}

        /// <summary>
        /// ���캯��������ȡ���ĺ�����ʹ�ã��ڲ�����throw new Exception(...);
        /// </summary>
        /// <param name="message">������Ϣ����</param>
        /// <param name="tmpObject">����� �������ڷ��͵��ͻ���</param>
        public HtException(string message, ASObject tmpObject) : base(tmpObject, message)
        {}

        /// <summary>
        /// ���캯��������ȡ���ĺ�����ʹ�ã��ڲ�����throw new Exception(...);
        /// </summary>
        /// <param name="message">������Ϣ����</param>
        /// <param name="inner">�����Exception����</param>
        /// <param name="tmpObject">����� �������ڷ��͵��ͻ���</param>
        public HtException(string message, Exception inner, ASObject tmpObject) : base(tmpObject, message, inner)
        {}

        /// <summary>
        /// ��¼��־����ʵ����HtException��ʹ��(�ڲ�����)
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
        /// ����һ���µ�HtException����
        /// </summary>
        /// <param name="code">������</param>
        /// <param name="message">������Ϣ����</param>
        /// <returns>һ���µ�HtException����</returns>
        public static HtException LogException(int code, string message)
        {
            var o = GetExceptionObjcet(code, message);
            var ex = new HtException(message,  o);
            ex.RwLog();
            return ex;
        }


        /// <summary>
        /// ���ݲ����Exception��������һ���µ�HtException����
        /// </summary>
        /// <param name="code">������</param>
        /// <param name="message">������Ϣ����</param>
        /// <param name="inner">�����Exception����</param>
        /// <returns>һ���µ�HtException����</returns>
        public static HtException LogException(int code, string message, Exception inner)
        {
            var o = GetExceptionObjcet(code, message, inner);
            var ex = new HtException(message, inner, o);
            ex.RwLog();
            return ex;
        }

        /// <summary>
        /// ����һ���µĴ���� ����
        /// </summary>
        /// <param name="code">������</param>
        /// <param name="what">������Ϣ����</param>
        /// <returns>����� ����</returns>
        private static ASObject GetExceptionObjcet(int code, string what)
        {
            var tmpobject = new ASObject();
            tmpobject["code"] = code;
            tmpobject["what"] = what;
            return tmpobject;
        }

        /// <summary>
        /// ���ݲ����Exception��������һ���µĴ���� ����
        /// </summary>
        /// <param name="code">������</param>
        /// <param name="what">������Ϣ����</param>
        /// <param name="ex">�����Exception����</param>
        /// <returns>����� ����</returns>
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
