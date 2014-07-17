using System;
using System.Collections.Generic;
using System.Text;
using System.Web;
using System.Net.Mail;
using System.Net;


namespace OBDServiceLib.include
{
    public class EmailFunction
    {
        public enum EmailType
        {
            /// <summary>
            /// 注册
            /// </summary>
            REG,
            /// <summary>
            /// 修改邮箱
            /// </summary>
            CHANGE_EMAIL,
            /// <summary>
            /// 修改密码
            /// </summary>
            CHANGE_PASSWORD,
        } 

        /// <summary>
        /// 
        /// </summary>
        /// <param name="emailType">EmailFunction.EmailType</param>
        /// <param name="EmailTitle">邮件标题</param>
        /// <param name="UserName">用户名</param>
        /// <param name="EmailCheckUrl">校验URL，不带Host</param>
        /// <param name="timeZoneOffSet">AS时区,如：北京时间为-480</param>
        /// <returns></returns>
        static public string GetEmailBody(EmailType emailType, string EmailTitle, string UserName, string EmailCheckUrl, Int32 timeZoneOffSet)
        {
            var emailBody = "";
            var tmpHost = HttpContext.Current.Request.Url.Host;
            var tmpPort = HttpContext.Current.Request.Url.Port == 80 ? "" : ":" + HttpContext.Current.Request.Url.Port.ToString();
            var WebSite = tmpHost + tmpPort;
            var SendTime = DateTime.UtcNow.AddHours(-timeZoneOffSet / 60);
            var InvalidTime = DateTime.UtcNow.AddHours(24 - timeZoneOffSet / 60);

            var langTag = ObdFunction.GetCulture();
            var filePath = "/emailTemplete/";
            switch (emailType)
            {
                case EmailType.REG:
                    filePath += "REG";
                    break;
                case EmailType.CHANGE_EMAIL:
                    filePath += "CHANGE_EMAIL";
                    break;
                case EmailType.CHANGE_PASSWORD:
                    filePath += "CHANGE_PASSWORD";
                    break;
            }
            filePath += "_" + langTag.ToLower() + ".html";
            filePath = HttpContext.Current.Server.MapPath(filePath);

            emailBody = ObdFunction.FileToString(filePath);
            emailBody = emailBody.Replace("${WebSite}", WebSite)
                .Replace("${EmailTitle}", EmailTitle)
                .Replace("${UserName}", UserName)
                .Replace("${EmailCheckUrl}", EmailCheckUrl);
                //.Replace("${SendTime}", TimeParser.GetDatetimeToString(SendTime))
                //.Replace("${InvalidTime}", TimeParser.GetDatetimeToString(InvalidTime));


            return emailBody;
        }

        /// <summary>
        /// 向指定邮箱发送邮件
        /// </summary>
        /// <param name="email">要发送邮件的邮箱</param>
        /// <param name="subject">邮件主题</param>
        /// <param name="body">邮件内容</param>
        /// <returns></returns>
        static public bool sendEmail(string email, string subject, string body)
        {
            try
            {
                //MailMessage mail = new MailMessage(ObdConfig.SendEmail, email);
                //mail.SubjectEncoding = Encoding.UTF8;
                //mail.BodyEncoding = Encoding.UTF8;
                //mail.IsBodyHtml = true; 
                //mail.Subject = subject;
                //mail.Body = body;

                //SmtpClient smtp = new SmtpClient(ObdConfig.SendEmailServer);
                //smtp.UseDefaultCredentials = false;//不使用默认凭据访问服务器 
                //smtp.DeliveryMethod = SmtpDeliveryMethod.Network;//使用network发送到smtp服务器 
                //smtp.Credentials = new NetworkCredential(ObdConfig.SendEmailUser, ObdConfig.SendEmailPassword); //SMTP 验证
                //smtp.Send(mail);
                //return true;

                MailMessage msg = new MailMessage(ObdConfig.SendEmail, email);
                msg.SubjectEncoding = Encoding.UTF8;
                msg.BodyEncoding = Encoding.UTF8;
                msg.IsBodyHtml = true;
                msg.Subject = subject;
                msg.Body = body;
                SmtpClient client = new SmtpClient(ObdConfig.SendEmailServer);
                if (ObdConfig.EnableSsl == false)
                {
                    client.UseDefaultCredentials = false;
                }

                client.Credentials = new NetworkCredential(ObdConfig.SendEmailUser, ObdConfig.SendEmailPassword);

                if (ObdConfig.EnableSsl == true)
                {
                    client.EnableSsl = ObdConfig.EnableSsl;
                }

                client.Send(msg);

                return true;

            }
            catch (Exception ex)
            {
                HtException.LogException(25, ObdFunction.FormatFooName() + "发送邮件失败", ex);                
            }
            return false;
        }
    }
}
