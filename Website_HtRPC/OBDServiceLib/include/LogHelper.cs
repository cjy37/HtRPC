using System;
using System.Collections.Generic;
using System.Text;
using log4net;
using System.Collections;
using FluorineFx.AMF3;

namespace OBDServiceLib.include
{
    public class LogHelper
    {
        /// <summary>
        /// LOG记录日志对象
        /// </summary>
        protected static ILog Log;

        public LogHelper()
        {}

        /// <summary>
        /// 记录日志
        /// </summary>
        /// <param name="message">内容</param>
        /// <returns></returns>
        static public void LogError(string message,Exception ex)
        {
            createLog();
            Log.Error(message, ex);
        }
        static public void LogError(string message)
        {
            createLog();
            Log.Error(message);
        }

        static private void createLog()
        {
            if (null == Log)
                Log = LogManager.GetLogger("HtExceptionLogger");
        }
    }
}
