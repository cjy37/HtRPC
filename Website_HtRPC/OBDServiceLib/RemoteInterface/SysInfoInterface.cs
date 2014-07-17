using System;
using System.Collections;
using System.Collections.Generic;
using System.IO.IsolatedStorage;
using System.Web;
using System.Xml;
using System.Text;
using System.Configuration;
using System.Net;
using System.IO;

using System.Data;
using System.Data.SqlClient;
using System.Reflection;
using FluorineFx.Json;
using OBDServiceLib.include;
using FluorineFx;
using FluorineFx.AMF3;
using System.Globalization;


namespace OBDServiceLib.RemoteInterface
{
    /// <summary>
    ///  系统信息接口
    /// </summary>
    [RemotingService("Fluorine SysInfoInterface service")]
    public class SysInfoInterface
    {
        /// <summary>
        /// 数据库的记录集对象
        /// </summary>
        private DataSet _ds = new DataSet();
        
        /// <summary>
        /// 数据库操作类
        /// </summary>
        //private DbHelper _DBclass = new DbHelper();

        /// <summary>
        /// 构造函数
        /// </summary>
        public SysInfoInterface()
        {
            //初始化
            //_DBclass.StrConn(ObdConfig.DBConnString);
        }

        //public FXMessageList getTest(int id)
        //{
        //    return MessageListDAO.GetModel(id);
        //}

        //---------------------------------------------------------------------------------
        /// <summary>
        /// 发送数据
        /// </summary>
        /// <param name="arr">需要发送的接口与参数数据</param>
        /// <param name="rhObject">其他的头对象</param>
        /// <returns></returns>
        //public object[] Send(object arr, object rhObject)
        //{
        //    //创建远程调用对象
        //    var remoteObject = new RemoteObject();
        //    //发送
        //    return remoteObject.Send((Array)arr, (ASObject)rhObject);
        //}

        /// <summary>
        /// 批量调用WS的接口
        /// </summary>
        /// <param name="arr">每一个item是一个调用</param>
        /// <returns>每个调用的返回结果，以数组的形式</returns>
        public Array callWS(Array arr)
        {
            try
            {

                var arrayList = new ArrayList();
#if DEBUG
                if (!String.IsNullOrEmpty(SysInfoInterface.getCookie("username")))
                {
                    if (String.IsNullOrEmpty(SysInfoInterface.getSession("username")))
                        SysInfoInterface.setSession("username", SysInfoInterface.getCookie("username"));
                    if (String.IsNullOrEmpty(SysInfoInterface.getSession("password")))
                        SysInfoInterface.setSession("password", SysInfoInterface.getCookie("password"));
                }

                var username = SysInfoInterface.getSession("username");
                var password = SysInfoInterface.getSession("password");

                if (String.IsNullOrEmpty(username) || String.IsNullOrEmpty(password))
                {
                    var exuser = HtException.LogException(600, ObdFunction.FormatFooName() + "用户登录超时");
                    var str = "用户登录超时";
                    var obj = ObdFunction.ReASObject(600, str, exuser);
                    arrayList.Add(obj);
                }
                else
                {
#endif
                //遍历调用个数
                    foreach (ASObject caller in arr)
                    {
                        //获取类名及全路径, t为NULL时会报错
                        var className = caller["className"].ToString();
                        var methodName = caller["methodName"].ToString();

                        try
                        {

                            var parameters = (object[])caller["params"];
                            var returnValue = RemoteHelper.invokeService(className, methodName, parameters);
                            //加到返回列表
                            var ret = ObdFunction.ReASObject(0, returnValue);
                            arrayList.Add(ret);
                        }
                        catch (Exception ex)
                        {
                           // var str = "执行服务端方法出错：" + className + "::" + methodName;
                            var str = className + "::" + methodName;
                            var obj = ObdFunction.ReASObject(998, str, ex);
                            arrayList.Add(obj);

                            HtException.LogException(998, ObdFunction.FormatFooName() + str);
                        }
     
                    }
 #if DEBUG
                }
#endif
                    //返回结果列表
                return arrayList.ToArray();
            }
            catch (Exception ex)
            {
                throw HtException.LogException( 999, ObdFunction.FormatFooName() +" error "+ ex.Message, ex);
            }
        }

        public string SavePNG(ByteArray data, string fileName)
        {
            try
            {
                string uploadFolder = "/uploadFiles/image"; // 上传文件夹
                string path = HttpContext.Current.Server.MapPath(uploadFolder);
                DateTime now = DateTime.Now;

                if (String.IsNullOrEmpty(fileName))
                {
                    fileName = "" + now.Year + now.Month + now.Day + now.Hour + now.Minute + now.Second +
                               now.Millisecond + ".png";
                }

                string savePath = HttpContext.Current.Server.MapPath(uploadFolder + "/" + fileName);// Request.Form["fileName"];
                string returnPath = uploadFolder + "/" + fileName;
                uint len = data.Length;
                byte[] b = new byte[len];

                data.ReadBytes(b, 0, len);

                Directory.CreateDirectory(path);//创建文件夹 
                FileStream tmpStream = new FileStream(savePath, FileMode.OpenOrCreate);
                tmpStream.Write(b, 0, (int)len);
                tmpStream.Flush();
                tmpStream.Close();

                return returnPath;
            }
            catch (IsolatedStorageException ex)
            {
                throw HtException.LogException(Errorcode, ObdFunction.FormatFooName() + " 没有创建目录的权限", ex);
            }
            catch (Exception ex)
            {
                throw HtException.LogException(Errorcode, ObdFunction.FormatFooName() + " upload Error", ex);
            }

        }


        public void SetCulture(string cultureName)
        {
            ObdFunction.SetCulture(cultureName);
        }

        private const int Errorcode = 1002;
        /// <summary>
        /// 从DS获取数据库连接的设置
        /// </summary>
        /// <returns></returns>
        //public static object[] getDBConfig()
        //{
        //    try
        //    {
        //        //参数列表Array
        //        var tmpList = new ArrayList();

        //        //客户端附加头Object
        //        var tmpRHObject = new ASObject();

        //        //创建远程调用数组
        //        var rvArray = new RemoteMethodArray();

        //        //调用远程UpdateDAUSocketSetup方法
        //        var rmObject = new RemoteMethodObject("GetDBConfig", "GetSetupHandler");
                
        //        /* config.getObject */
        //        //把方法添加到数组
        //        rvArray.Add(rmObject.GetRemoteMethodObject());

        //        var tmpArr = rvArray.GetArray();

        //        var remoteObject = new RemoteObject();
        //        tmpArr, tmpRHObject)
        //        return remoteObject.CommitByTCP();
        //    }
        //    catch (Exception ex)
        //    {
        //        throw new HtException("获取数据库配置失败！请确认[DS]程序是否已启动", ex);
        //    }
        //}

        /// <summary>
        /// 取Cookie
        /// </summary>
        /// <param name="key"></param>
        /// <returns></returns>
        static public string getCookie(string key)
        {
            var domain = ObdConfig.CookieDomain;
            return getCookie(key, domain);
        }

        //-----------------------------------------------------------------------------------------
        /// <summary>
        /// 取Cookie
        /// </summary>
        /// <param name="key">键</param>
        /// <returns></returns>
        static public string getCookie(string key, string domain)
        {
            try
            {
                if (string.IsNullOrEmpty(domain))
                    domain = ObdConfig.CookieDomain;

                HttpCookie tmpCookie = HttpContext.Current.Request.Cookies.Get(domain);
                var val = tmpCookie.Values.Get(key);

                return DESEncrypt.Decrypt(val);
            }
            catch (Exception)
            {
                //HtException.LogException(555, err.Message);
            }
            return null;
        }

        /// <summary>
        /// 清除Cookie
        /// </summary>
        /// <returns></returns>
        static public string clearCookie(string domain)
        {
            try
            {
                HttpContext.Current.Response.Cookies.Clear();

                HttpCookie tmpCookie = null;
                if (HttpContext.Current != null
                    && HttpContext.Current.Request != null
                    && HttpContext.Current.Request.Cookies != null)
                    tmpCookie = HttpContext.Current.Request.Cookies.Get(domain);

                if (null != tmpCookie)
                {
                
                    tmpCookie.Expires = DateTime.Now.AddDays(-1);
                    HttpContext.Current.Response.Cookies.Add(tmpCookie);
                }
            return "OK";
            }
            catch (Exception err)
            {
                return "err:" + err.Message;
            }          
        }

        /// <summary>
        /// 设置Cookie（加密）
        /// </summary>
        /// <param name="key"></param>
        /// <param name="val"></param>
        /// <returns></returns>
        static public string setCookie(string key, string val)
        {
            var domain = ObdConfig.CookieDomain;
            return setCookie(key, val, domain);
        }

        /// <summary>
        /// 设置Cookie（加密）
        /// </summary>
        /// <param name="key">键</param>
        /// <param name="val">值</param>
        /// <returns></returns>
        static public string setCookie(string key, string val, string domain)
        {
            try
            {
                val = DESEncrypt.Encrypt(val);
                if (string.IsNullOrEmpty(domain))
                    domain = ObdConfig.CookieDomain;
                var tmpcookies = HttpContext.Current.Request.Cookies.Get(domain) ?? new HttpCookie(domain);
                var tmpKey = tmpcookies.Values[key];
                if (null == tmpKey)
                    tmpcookies.Values.Add(key, val);
                else
                    tmpcookies.Values[key] = val;
                tmpcookies.Expires = DateTime.Now.AddDays(365);
                HttpContext.Current.Response.Cookies.Add(tmpcookies);
                return "OK";
            }
            catch (Exception err)
            {
                return "err:" + err.Message;
            }
            
        }

        /// <summary>
        /// 获取指定key的键值
        /// </summary>
        /// <param name="key">键</param>
        /// <returns></returns>
        static public string getSession(string key)
        {
            try
            {
                if (HttpContext.Current != null)
                  return HttpContext.Current.Session[key].ToString();
            }           
            catch (Exception)
            {
                //return err.Message;
            }
            return "";
        }

        /// <summary>
        /// 设置Session
        /// </summary>
        /// <param name="key">键</param>
        /// <param name="value">值</param>
        /// <returns></returns>
        static public string setSession(string key, string value)
        {
            try
            {
                HttpContext.Current.Session[key] = value;
                return "OK";
            }
            catch (Exception err)
            {
                return "err:" + err.Message;
            }
            
        }
    }
}
