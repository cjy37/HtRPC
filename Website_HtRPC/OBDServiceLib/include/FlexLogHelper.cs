using System;
using System.Collections.Generic;
using System.Text;
using log4net;
using System.Collections;
using FluorineFx.AMF3;
using FluorineFx;


namespace OBDServiceLib.include
{
    public class FlexLogHelper
    {
        protected static ILog FlexLog;

        public FlexLogHelper()
        {
        }

        /// <summary>
        /// 记录日志
        /// </summary>
        /// <param name="username">客户端用户名</param>
        /// <param name="message">内容</param>
        /// <returns></returns>
        public static bool LogError(string username, ByteArray message)
        {
            if (null == FlexLog)
                FlexLog = LogManager.GetLogger("FlexLoglogger");

            string msg = message.ReadObject().ToString();//.Replace("\n","\r");
            FlexLog.Debug("[username]:" + username + "\nmessage:" + msg);

            return true;
        }
    }
}
