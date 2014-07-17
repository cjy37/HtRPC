using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using System.Web.Routing;

namespace WebApp
{
    // Note: For instructions on enabling IIS6 or IIS7 classic mode, 
    // visit http://go.microsoft.com/?LinkId=9394801

    public class MvcApplication : System.Web.HttpApplication
    {
        public static void RegisterRoutes(RouteCollection routes)
        {
            routes.IgnoreRoute("{resource}.axd/{*pathInfo}");

            routes.MapRoute(
                "Default",                                              // Route name
                "{controller}/{action}/{id}",                           // URL with parameters
                new { controller = "Login", action = "Default", id = "" }  // Parameter defaults
            );
        }

        protected void Application_Start()
        {
            AreaRegistration.RegisterAllAreas();

            RegisterRoutes(RouteTable.Routes);
        }

        protected void Session_Start(object sender, EventArgs e)
        {
            //解决bug 会话状态已创建一个会话 ID，但由于响应已被应用程序刷新而无法保存它。
            string sessionId = Session.SessionID;
        }


        /// <summary>
        /// 系统异常捕获（若方法内有捕获，则该部分失效）
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        //protected void Application_Error(object sender, EventArgs e)
        //{
        //    var exception = Server.GetLastError();

        //    var httpException = exception as HttpException;

        //    string url = HttpContext.Current.Request.Url.ToString();
        //    string receiver = ConfigHelper.GetConfigString("SendEmail");
        //    bool isSendMail = ConfigHelper.GetConfigBool("IsSysErrorMail");

        //    //cs代码异常
        //    if (httpException == null)
        //    {
        //        if (isSendMail)
        //            MailSender.Send(receiver, url, exception.Message + "\r\n" + exception.StackTrace);
        //    }
        //    else
        //    { 
        //        //http异常
        //        switch (httpException.GetHttpCode())
        //        {
        //            case 500:
        //                if (isSendMail)
        //                    MailSender.Send(receiver, url, exception.Message + "\r\n" + exception.StackTrace);
        //                break;
        //        }
        //    }

        //    LogHelper.LogDebug(System.Reflection.MethodBase.GetCurrentMethod().ReflectedType.FullName, System.Reflection.MethodBase.GetCurrentMethod().Name, exception.Message, exception.StackTrace);
        //}
    }
}