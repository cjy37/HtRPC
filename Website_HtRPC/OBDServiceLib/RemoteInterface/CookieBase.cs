#if uuroad2
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Web;
using OBDServiceLib.include;
using System.Data;

namespace OBDServiceLib.RemoteInterface
{
    /// <summary>
    /// 对Cookie的写入与读取操作
    /// </summary>
    public class CookieBase
    {
        #region --会员登录，写入会员信息
        /// <summary>
        /// 
        /// </summary>
        /// <param name="userInfo"></param>
        /// <returns></returns>
        public static bool SetCookieUserInfo(T_UserInfo userInfo)
        {
            bool ret = false;

            try
            {
                if (userInfo != null)
                {
                    OptionCookie curCookie = new OptionCookie(HttpContext.Current);
                    ret = curCookie.SetCookieUserInfo(userInfo);
                }
            }
            catch{}

            return ret;
        }
        #endregion

        #region 退出站点清理COOKIE
        public static bool ClearWebSiteCookie()
        {
            OptionCookie curCookie = new OptionCookie(HttpContext.Current);
            return curCookie.ClearWebSiteCookie();
        }
        #endregion

        #region BBS论坛登录
        public static bool LoginBBS(string userName, string passWord)
        {
            OptionCookie curCookie = new OptionCookie(HttpContext.Current);
            return curCookie.LoginBBS(userName, passWord);
        }
        #endregion


        #region BBS论坛管理后台登录
        public static bool LoginBBSAdmin(string userName, string passWord)
        {
            OptionCookie curCookie = new OptionCookie(HttpContext.Current);
            return curCookie.LoginBBSAdmin(userName, passWord);
        }
        #endregion


        #region 退出BBS清理COOKIE
        public static bool BBSLogOutClearCookie()
        {
            OptionCookie curCookie = new OptionCookie(HttpContext.Current);
            return curCookie.BBSLogOutClearCookie();
        }
        #endregion

        #region 退出BBS管理后台清理COOKIE
        public static bool BBSAdminLogOutClearCookie()
        {
            OptionCookie curCookie = new OptionCookie(HttpContext.Current);
            return curCookie.BBSAdminLogOutClearCookie();
        }
        #endregion
    }

    /// <summary>
    /// COOKIE操作类
    /// </summary>
    public class OptionCookie : Discuz.Forum.PageBase
    {
        private HttpContext context;

        public OptionCookie()
            : base()
        {
            //TODO: 在此处添加构造函数逻辑
        }

        public OptionCookie(HttpContext curContext)
        {
            this.context = curContext;
        }

        #region  设置COOKIE
        /// <summary>
        /// 设置COOKIE
        /// </summary>
        /// <param name="userInfo"></param>
        /// <returns></returns>
        public bool SetCookieUserInfo(T_UserInfo userInfo)
        {
            bool ret = false;

            string key_username = string.Empty;
            string key_password = string.Empty;
            if (userInfo.C_UserType.Value.ToString() == "1" || userInfo.C_UserType.Value.ToString() == "3")
            {
                key_username = "username";
                key_password = "password";
            }
            else if (userInfo.C_UserType.Value.ToString() == "4")
            {
                key_username = "sysUsername";
                key_password = "sysPassword";
            }

            try
            {
                if (userInfo != null)
                {
                    context.Session[key_username] = userInfo.C_UserName.Value;
                    context.Session[key_password] = userInfo.C_UserPassword.Value;

                    string domain = ObdConfig.CookieDomain;
                    //string domain = Htxw.BLL.Base.B_Config.GetConfig(SysEnum.DomainConfig.Domain);

                    setCookie(key_username, userInfo.C_UserName.Value, domain);
                    setCookie(key_password, userInfo.C_UserPassword.Value, domain);

                    ret = true;
                }
            }
            catch {}

            return ret;
        }
        #endregion


        #region 设置Cookie（加密）
        /// <summary>
        /// 设置Cookie（加密）
        /// </summary>
        /// <param name="key">键</param>
        /// <param name="val">值</param>
        /// <returns></returns>
        public void setCookie(string key, string val, string domain)
        {
            try
            {
                val = DESEncrypt.Encrypt(val);
                if (string.IsNullOrEmpty(domain))
                {
                    domain = ObdConfig.CookieDomain;
                    //domain = Htxw.BLL.Base.B_Config.GetConfig(SysEnum.DomainConfig.Domain);
                }
                var tmpcookies = context.Request.Cookies.Get(domain) ?? new HttpCookie(domain);
                var tmpKey = tmpcookies.Values[key];
                if (null == tmpKey)
                {
                    tmpcookies.Values.Add(key, val);
                }
                else
                {
                    tmpcookies.Values[key] = val;
                }
                tmpcookies.Expires = DateTime.Now.AddDays(1);
                context.Response.Cookies.Add(tmpcookies);
            }
            catch {}
        }
        #endregion

        #region 取Cookie
        /// <summary>
        /// 取Cookie
        /// </summary>
        /// <param name="key">键</param>
        /// <returns></returns>
        public string getCookie(string key, string domain)
        {
            try
            {
                if (string.IsNullOrEmpty(domain))
                {
                    domain = ObdConfig.CookieDomain;
                    //domain = Htxw.BLL.Base.B_Config.GetConfig(SysEnum.DomainConfig.Domain);
                }

                HttpCookie tmpCookie = context.Request.Cookies.Get(domain);
                var val = tmpCookie.Values.Get(key);

                return DESEncrypt.Decrypt(val);
            }
            catch {}
            return null;
        }
        #endregion

        #region 获取指定key的键值
        /// <summary>
        /// 获取指定key的键值
        /// </summary>
        /// <param name="key">键</param>
        /// <returns></returns>
        public string getSession(string key)
        {
            string returnString = string.Empty;

            try
            {
                if (context != null && context.Session != null)
                {
                    returnString = context.Session[key].ToString();
                }
            }
            catch {}
            return returnString;
        }
        #endregion

        #region 设置Session
        /// <summary>
        /// 设置Session
        /// </summary>
        /// <param name="key">键</param>
        /// <param name="value">值</param>
        /// <returns></returns>
        public bool setSession(string key, string value)
        {
            bool returnResult = false;

            try
            {
                if (context != null && context.Session != null)
                {
                    context.Session.Add(key, value);
                    returnResult = true;
                }
            }
            catch {}

            return returnResult;
        }
        #endregion

        #region 清除Cookie
        /// <summary>
        /// 清除Cookie
        /// </summary>
        /// <returns></returns>
        public bool ClearCookie(string domain)
        {
            bool ret = true;

            try
            {
                context.Response.Cookies.Clear();

                HttpCookie tmpCookie = null;
                if (context != null && context.Request != null && context.Request.Cookies != null)
                {
                    if (string.IsNullOrEmpty(domain))
                    {
                        domain = ObdConfig.CookieDomain;
                    }
                    tmpCookie = context.Request.Cookies.Get(domain);
                }

                if (null != tmpCookie)
                {
                    tmpCookie.Expires = DateTime.Now.AddDays(-1);
                    context.Response.Cookies.Add(tmpCookie);
                }
            }
            catch (Exception ex)
            {
                ret = false;
            }

            return ret;
        }
        #endregion

        #region 退出站点清理COOKIE
        public bool ClearWebSiteCookie()
        {
            bool ret = true;

            try
            {
                //if (ClearCookie(Htxw.BLL.Base.B_Config.GetConfig(SysEnum.DomainConfig.Domain)))
                if (ClearCookie(ObdConfig.CookieDomain))
                {
                    context.Session.Clear();
                }
                else
                {
                    ret = false;
                }
            }
            catch (Exception ex)
            {
                ret = false;
            }

            return ret;
        }
        #endregion

        #region 论坛登录
        public bool LoginBBS(string userName, string passWord)
        {
            bool ret = true;

            username = userName;
            password = passWord;

            int uid = -1;
            //if (context.Session["dntuserid"] != null)
            //{
                #region 根据用户名和密码找id
                try
                {
                    Microsoft.Practices.EnterpriseLibrary.Data.Database db = Microsoft.Practices.EnterpriseLibrary.Data.DatabaseFactory.CreateDatabase();
                    System.Data.Common.DbConnection conn = null;
                    try
                    {
                        conn = db.CreateConnection();
                        conn.Open();
                        System.Data.Common.DbCommand com = conn.CreateCommand();
                        StringBuilder sql = new StringBuilder();
                        sql.Append("select uid from [dnt]..dnt_users ")
                           .Append(" where username='")
                           .Append(username)
                           .Append("' and password='")
                           .Append(password)
                           .Append("'");
                        com.CommandText = sql.ToString();
                        System.Data.Common.DbDataReader reader = com.ExecuteReader();
                        while (reader.Read())
                        {
                            if (!reader.IsDBNull(0))
                            {
                                uid = Convert.ToInt32(reader[0]);
                                context.Session["dntuserid"] = uid.ToString();
                                break;
                            }
                        }

                    }
                    catch { }
                    finally
                    {
                        if (null != conn && conn.State != System.Data.ConnectionState.Closed)
                        {
                            conn.Close();
                            conn.Dispose();
                        }
                    }
                }
                catch { }
                #endregion
            //}
            if (uid != -1)
            {
                try
                {
                    ShortUserInfo userinfo = Users.GetShortUserInfo(uid);

                    LoginLogs.DeleteLoginLog(DNTRequest.GetIP());
                    UserCredits.UpdateUserCredits(uid);
                    ForumUtils.WriteUserCookie(
                            uid,
                            Utils.StrToInt(DNTRequest.GetString("expires"), 9999),
                            config.Passwordkey,
                            DNTRequest.GetInt("templateid", 0),
                            DNTRequest.GetInt("loginmode", -1));

                    OnlineUsers.UpdateAction(olid, UserAction.Login.ActionID, 0);
                    //无延迟更新在线信息
                    oluserinfo = OnlineUsers.UpdateInfo(config.Passwordkey, config.Onlinetimeout);
                    olid = oluserinfo.Olid;
                    Users.UpdateUserLastvisit(uid, DNTRequest.GetIP());

                    string reurl = Utils.UrlDecode(ForumUtils.GetReUrl());


                    APIConfigInfo apiInfo = APIConfigs.GetConfig();
                    //if (apiInfo.Enable)
                    //{
                    //    APILogin(apiInfo);
                    //}

                    userid = uid;
                    usergroupinfo = UserGroups.GetUserGroupInfo(userinfo.Groupid);
                    // 根据用户组得到相关联的管理组id
                    useradminid = usergroupinfo.Radminid;

                    SetMetaRefresh();
                }
                catch
                {
                    ret = false;
                }
            }
            else
            {
                ret = false;
            }

            return ret;
        }
        #endregion


        #region 论坛管理后台登录
        public bool LoginBBSAdmin(string userName, string passWord)
        {
            bool ret = true;

            DataTable dt = new DataTable();
            if (config.Passwordmode == 1)
            {
                int uid = -1;
                if (context.Session["dntuserid"] != null) uid = Convert.ToInt32(context.Session["dntuserid"]);
                if (uid != -1) dt = Discuz.Data.DatabaseProvider.GetInstance().GetUserInfo(uid);
            }
            else
            {
                dt = DatabaseProvider.GetInstance().GetUserInfo(userName.Trim(), passWord.Trim());
            }

            if (dt.Rows.Count > 0)
            {
                UserGroupInfo usergroupinfo = AdminUserGroups.AdminGetUserGroupInfo(Convert.ToInt32(dt.Rows[0]["groupid"].ToString()));

                if (usergroupinfo.Radminid == 1)
                {
                    ForumUtils.WriteUserCookie(Convert.ToInt32(dt.Rows[0]["uid"].ToString().Trim()), 9999, GeneralConfigs.GetConfig().Passwordkey);

                    int userid = Convert.ToInt32(dt.Rows[0]["uid"].ToString().Trim());
                    string username = userName.Trim();
                    int usergroupid = Convert.ToInt16(dt.Rows[0]["groupid"].ToString().Trim());
                    string secques = dt.Rows[0]["secques"].ToString().Trim();
                    string ip = DNTRequest.GetIP();

                    UserGroupInfo __usergroupinfo = AdminUserGroups.AdminGetUserGroupInfo(usergroupid);

                    string grouptitle = __usergroupinfo.Grouptitle;


                    HttpCookie cookie = new HttpCookie("dntadmin");
                    cookie.Values["key"] = ForumUtils.SetCookiePassword(passWord.Trim() + secques + userid.ToString(), config.Passwordkey);
                    cookie.Expires = DateTime.Now.AddMinutes(9999);
                    HttpContext.Current.Response.AppendCookie(cookie);

                    AdminVistLogs.InsertLog(userid, username, usergroupid, grouptitle, ip, "后台管理员登陆", "");

                    try
                    {
                        SoftInfo.LoadSoftInfo();
                    }
                    catch
                    {
                        ret = false;
                    }

                    //升级general.config文件
                    try
                    {
                        GeneralConfigs.Serialiaze(GeneralConfigs.GetConfig(), Server.MapPath("../bbsweb/config/general.config"));
                    }
                    catch
                    {
                        ret = false;
                    }
                }
                else
                {
                    ret = false;
                }
            }
            else
            {
                ret = false;
            }

            return ret;
        }
        #endregion


        #region 论坛退出清理COOCKIE
        public bool BBSLogOutClearCookie()
        {
            bool ret = true;

            try
            {
                int uid = userid;
                userid = -1;
                //StringBuilder script = new StringBuilder();
                //script.Append("if (top.document.getElementById('leftmenu')){");
                //script.Append("		top.frames['leftmenu'].location.reload();");
                //script.Append("}");

                //base.AddScript(script.ToString());

                //string referer = DNTRequest.GetQueryString("reurl");
                //if (!DNTRequest.IsPost() || referer != "")
                //{
                //    string r = "";
                //    if (referer != "")
                //    {
                //        r = referer;
                //    }
                //    else
                //    {
                //        if ((DNTRequest.GetUrlReferrer() == "") || (DNTRequest.GetUrlReferrer().IndexOf("login") > -1) ||
                //            DNTRequest.GetUrlReferrer().IndexOf("logout") > -1)
                //        {
                //            r = "index.aspx";
                //        }
                //        else
                //        {
                //            r = DNTRequest.GetUrlReferrer();
                //        }
                //    }
                //    Utils.WriteCookie("reurl", (referer == "" || referer.IndexOf("login.aspx") > -1) ? r : referer);
                //}


                //SetUrl(Utils.UrlDecode(ForumUtils.GetReUrl()));

                //SetMetaRefresh();
                //SetShowBackLink(false);
                //if (DNTRequest.GetString("userkey") == userkey || IsApplicationLogout())
                //{

                //AddMsgLine("已经清除了您的登录信息, 稍后您将以游客身份返回首页");
                //Users.UpdateOnlineTime(uid);
                OnlineUsers.DeleteRows(olid);
                ForumUtils.ClearUserCookie();
                Utils.WriteCookie(Utils.GetTemplateCookieName(), "", -999999);

                System.Web.HttpCookie cookie = new System.Web.HttpCookie("dntadmin");
                context.Response.AppendCookie(cookie);

                //}
                //else
                //{
                //    ret = false;
                //}
            }
            catch (Exception ex)
            {
                ret = false;
            }

            return ret;
        }


        #region 论坛管理后台退出清理COOCKIE
        public bool BBSAdminLogOutClearCookie()
        {
            bool ret = true;

            try
            {
                //更新在线表相关用户信息
                config = GeneralConfigs.GetConfig();
                OnlineUserInfo oluserinfo = OnlineUsers.UpdateInfo(config.Passwordkey, config.Onlinetimeout);
                if (AdminUserGroups.AdminGetUserGroupInfo(oluserinfo.Groupid).Radminid != 1)
                {
                    //HttpContext.Current.Response.Redirect("../");
                    //return;
                    ret = false;
                }
                int olid = oluserinfo.Olid;
                OnlineUsers.DeleteRows(olid);

                //清除Cookie
                ForumUtils.ClearUserCookie();
                HttpCookie cookie = new HttpCookie("dntadmin");
                HttpContext.Current.Response.AppendCookie(cookie);

                System.Web.Security.FormsAuthentication.SignOut();
            }
            catch
            {
                ret = false;
            }

            return ret;
        }
        #endregion


        private bool IsApplicationLogout()
        {
            APIConfigInfo apiconfig = APIConfigs.GetConfig();
            if (!apiconfig.Enable)
            {
                return false;
            }

            int confirm = DNTRequest.GetFormInt("confirm", -1);
            if (confirm != 1)
            {
                return false;
            }

            return true;
        }
        #endregion
    }
}
#endif