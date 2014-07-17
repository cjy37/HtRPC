using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Text;
using System.Net.Mail;
using System.Net;
using System.Web;
using System.Globalization;
using System.Threading;
using OBDServiceLib.RemoteInterface;
using FluorineFx;
using System.Collections;
using System.Data;
using System.IO;
using System.Reflection;


namespace OBDServiceLib.include
{
    public class ObdFunction
    {
        private const int Errorcode = 1001;

        /// <summary>
        /// 获取语言设置字符串
        /// </summary>
        /// <returns></returns>
        public static void SetCulture(string cultureName)
        {
            cultureName = cultureName.ToLower().Replace("_", "-");
            //UICulture - 决定了采用哪一种本地化资源，也就是使用哪种语言
            //Culture - 决定各种数据类型是如何组织，如数字与日期
            Thread.CurrentThread.CurrentUICulture = new CultureInfo(cultureName);
            Thread.CurrentThread.CurrentCulture = CultureInfo.CreateSpecificCulture(cultureName);

            var lang = SysInfoInterface.getCookie("sysUserLang", "lang");
            if (lang == cultureName) return;
            SysInfoInterface.setCookie("sysUserLang", cultureName, "lang");
        }

        public static string GetCulture()
        {
            var lang = SysInfoInterface.getCookie("sysUserLang", "lang");
            if (String.IsNullOrEmpty(lang))
            {
                String[] userLang = HttpContext.Current.Request.UserLanguages;
                if (userLang.Length > 0)
                    lang = userLang[0].ToLower();
            }
            if (String.IsNullOrEmpty(lang))
            {
                lang = ObdConfig.GetAppSettings("DefaultCulture");
            }
            return lang;
        }

        /// <summary>
        /// 获取标识  例如  修改邮箱时，写进的标识
        /// </summary>
        /// <returns></returns>
        static public string GetCheckTag()
        {
            try
            {
                var tag = SysInfoInterface.getSession("checkTag");

                SysInfoInterface.setSession("checkTag", "");

                if (!String.IsNullOrEmpty(tag))
                {
                    return tag;
                }
                else
                    return "";
            }
            catch (Exception)
            {
                throw;// HtException.LogException(Errorcode, ObdFunction.FormatFooName() + " error", ex);
            }
        }


        //-----------------------------------------------------------------------------------------------


        /// <summary>
        /// 转换DataSet数据库表的格式，转换为ArrayList格式，每一元素是一个AsObject
        /// /给AsObject添加属性键值对，
        /// </summary>
        /// <param name="ds">数据库记录集</param>
        /// <returns></returns>
        public static ArrayList TableToList(DataSet ds)
        {
            var arrList = new ArrayList();
            if (null == ds || ds.Tables.Count == 0)
                return arrList;
            var dt = ds.Tables[0];

            foreach (DataRow row in dt.Rows)
            {
                var rowObject = new ASObject();
                foreach (DataColumn column in dt.Columns)
                {
                    var columnValue = row[column.ColumnName];
                    if (columnValue is DateTime)
                    {
                        var tmps = (DateTime)columnValue;
                        columnValue = new DateTime(tmps.Ticks, DateTimeKind.Utc);
                    }
                    //给AsObject添加属性键值对，此种方式自由度高，一定要规定好SQL语句
                    rowObject.Add(column.ColumnName, columnValue);
                }
                //添加AsObject到数组
                arrList.Add(rowObject);
            }
            return arrList;
        }


        /// <summary>
        /// 转换DataSet数据库表的格式，转换为List<T>对象，每一元素是一个泛类型的对象
        /// </summary>
        /// <typeparam name="T">泛类型</typeparam>
        /// <param name="ds">DataSet</param>
        /// <returns>泛型列表</returns>
        public static List<T> TableToList<T>(DataSet ds)
        {
            var dt = ds.Tables[0];
            var list = new List<T>();
            var t=typeof(T);
            foreach (DataRow row in dt.Rows)
            {
                var rowInstance = Activator.CreateInstance(t);     //用反射来构造“机组”类，缺点：空值还要做处理，函数的通用性不足！且SQL语句有误则要做多处改动
                foreach (DataColumn column in dt.Columns)
                {
                    try
                    {
                        var columnValue = row[column.ColumnName];
                        //空值过滤
                        if (Convert.IsDBNull(columnValue)) continue; 
                        if (columnValue is DateTime)
                        {
                            var tmps = (DateTime)columnValue;
                            columnValue = new DateTime(tmps.Ticks, DateTimeKind.Utc);
                        }

                        //反射，给myObj添加属性的值，此种方式自由度高，一定要规定好SQL语句
                        PropertyInfo rowPropertyInfo = t.GetProperty(column.ColumnName);
                        FieldInfo rowField = t.GetField(column.ColumnName);
                        if (rowPropertyInfo == null && rowField == null)
                            continue;
                        else if (rowPropertyInfo != null)
                            rowPropertyInfo.SetValue(rowInstance, Convert.ChangeType(columnValue, rowPropertyInfo.PropertyType), null);
                        else
                            rowField.SetValue(rowInstance, Convert.ChangeType(columnValue, rowField.FieldType));
                    }
                    catch (Exception ex)
                    {
                        throw new HtException(ObdFunction.FormatFooName() + " error", ex);
                    }
                }
                //添加到LIST
                list.Add((T)rowInstance);
            }
            return list;
        }


        /// <summary>
        /// AssembleData所使用回调函数的代理申明
        /// </summary>
        /// <param name="row">数据库表的某一行</param>
        /// <param name="columns">数据库表的列（VO）</param>
        /// <param name="type">装载类型</param>
        /// <param name="databaseInfo">预留的二次取数据库的信息</param>
        /// <returns>Object</returns>
        public delegate Object AssembleFunction<TType>(DataRow row, DataColumnCollection columns, Object databaseInfo);

        /// <summary>
        /// 转换DataSet数据库表的格式，转换为ArrayList对象
        /// 每条数据的构造方法又function执行
        /// </summary>
        /// <param name="ds">数据库表的DataSet</param>
        /// <param name="type">记录存储类型（VO）</param>
        /// <param name="function">每条记录的够造</param>
        /// <returns>ArrayList</returns>
        public static ArrayList AssembleData<TType>(DataSet ds, AssembleFunction<TType> function, Object databaseInfo)
        {
            /*---------------------------------------------------*/
            if (ds.Tables.Count == 0)
                return null;

            var dt = ds.Tables[0];
            var rows = dt.Rows;
            var columns = dt.Columns;
            var list = new ArrayList();

            foreach (DataRow row in rows)
            {
                var obj = function(row, columns, databaseInfo);
                list.Add(obj);
            }
            return list;
        }

        /// <summary>
        /// 返回给FLEX的数据统一格式
        /// </summary>
        /// <param name="code">状态码，0表正常，其他的请参考《错误码表》</param>
        /// <param name="what">错误描述</param>
        /// <param name="value">返回值</param>
        /// <returns>array</returns>
        public static ASObject ReASObject(int code, object value)
        {
            var asobject = new ASObject();
            
            asobject.Add("code", code);
            asobject.Add("ret", value);
            
            return asobject;
        }

        public static ASObject ReASObject(int code, string what, object RootCause)
        {
            var asobject = new ASObject();
            
            asobject.Add("code", code);
            asobject.Add("what", what);

            if (null != RootCause)
                asobject.Add("RootCause", RootCause);

            return asobject;
        }

        /// <summary>
        /// 获取一个机组编码格式的字符串
        /// </summary>
        /// <returns></returns>
        //public static string GetMachineId()
        //{
        //    var tmpString = DateTime.UtcNow.ToString("yyMMddHHmmss") + GetRandom(0,99999).ToString("D5");
        //    return tmpString;
        //}

        /// <summary>
        /// 获取一个随机数
        /// </summary>
        /// <param name="minValue">最小值</param>
        /// <param name="maxValue">最大值</param>
        /// <returns>随机数</returns>
        //public static int GetRandom(int minValue,int maxValue)
        //{
        //    var r = new Random(unchecked((int)DateTime.UtcNow.Ticks));
        //    var iResult = r.Next(minValue, maxValue);
        //    return iResult;
        //}



        /// <summary>
        /// 格式化一个树数据
        /// </summary>
        /// <param name="dt">数据表</param>
        /// <param name="pid">父ID</param>
        /// <param name="parent">父对象</param>
        /// <returns>树数据</returns>
        //public static List<FXFolder> GetTreeObject(DataTable dt, int pid, FXFolder parent)
        //{
        //    try
        //    {
        //        var strExpression = "[pid]=" + pid;
        //        var dr = dt.Select(strExpression);
        //        var folderList = new List<FXFolder>();

        //        if (dr.GetUpperBound(0) > -1)
        //        {
        //            //count1--;
        //            for (var i = 0; i <= dr.GetUpperBound(0); i++)
        //            {
        //                var folder = new FXFolder();


        //                if(parent!=null)
        //                    folder.parent = parent;
        //                folder.id = Convert.ToInt32(dr[i]["id"]);
        //                folder.name = Convert.ToString(dr[i]["name"]);
        //                folder.root = Convert.ToInt32(dr[i]["root"]);
        //                folder.pid = Convert.ToInt32(dr[i]["pid"]);
        //                folder.depth = Convert.ToInt32(dr[i]["depth"]);
        //                folder.path = Convert.ToString(dr[i]["path"]);
        //                folder.desc = Convert.ToString(dr[i]["desc"]);
        //                folder.xml_config = Convert.ToString(dr[i]["xml_config"]);

        //                var tmparray = GetTreeObject(dt, folder.id, folder);
        //                if (tmparray.ToArray().Length == 0 && folder.depth <= 1)
        //                    continue;

        //                folder.children = tmparray;

        //                folderList.Add(folder);
        //            }
        //        }
        //        return folderList;
        //    }
        //    catch (Exception e)
        //    {
        //        throw new HtException(ObdFunction.FormatFooName() + " error", ex);
        //    }
        //}


        /* - - - - - - - - - - - - - - - - - - - - - - - - 
        * Stream 和 byte[] 之间的转换 
        * - - - - - - - - - - - - - - - - - - - - - - - */
        /// <summary>
        /// 将 Stream 转成 byte[] 
        /// </summary>
        /// <param name="stream">stream对象</param>
        /// <returns>byte[]对象</returns>
        static public byte[] StreamToBytes(Stream stream)
        {
            var bytes = new byte[stream.Length];
            stream.Read(bytes, 0, bytes.Length);
            // 设置当前流的位置为流的开始 
            stream.Seek(0, SeekOrigin.Begin);
            return bytes;
        }

        /// <summary>
        /// 将 byte[] 转成 Stream 
        /// </summary>
        /// <param name="bytes">byte[]对象</param>
        /// <returns>stream对象</returns>
        static public Stream BytesToStream(byte[] bytes)
        {
            Stream stream = new MemoryStream(bytes);
            return stream;
        }

        /* - - - - - - - - - - - - - - - - - - - - - - - - 
         * Stream 和 文件之间的转换 
         * - - - - - - - - - - - - - - - - - - - - - - - */
        /// <summary>
        /// 将 Stream 写入文件 
        /// </summary>
        /// <param name="stream">stream对象</param>
        /// <param name="fileName">文件路径</param>
        static public void StreamToFile(Stream stream, string fileName)
        {
            // 把 Stream 转换成 byte[] 
            var bytes = new byte[stream.Length];
            stream.Read(bytes, 0, bytes.Length);
            // 设置当前流的位置为流的开始 
            stream.Seek(0, SeekOrigin.Begin);
            // 把 byte[] 写入文件 
            var fs = new FileStream(fileName, FileMode.Create);
            var bw = new BinaryWriter(fs);
            bw.Write(bytes);
            bw.Close();
            fs.Close();
        }

        /// <summary>
        /// 从文件读取 Stream 
        /// </summary>
        /// <param name="fileName">文件路径</param>
        /// <returns>MemoryStream对象</returns>
        static public MemoryStream FileToStream(string fileName)
        {
            try
            {
                // 打开文件 
                var fileStream = (Stream)new FileStream(fileName, FileMode.Open, FileAccess.Read, FileShare.Read);
                // 读取文件的 byte[] 
                var bytes = new byte[fileStream.Length];
                fileStream.Read(bytes, 0, bytes.Length);
                fileStream.Close();
                // 把 byte[] 转换成 Stream 
                var stream = new MemoryStream(bytes);
                return stream;
            }
            catch (Exception ex)
            {
                throw new HtException(ObdFunction.FormatFooName() + " error", ex);
            }
        }

        static public string FileToString(string filePath)
        {
            StreamReader TxtReader = new StreamReader(filePath,System.Text.Encoding.Default);
            string FileContent;
            FileContent = TxtReader.ReadToEnd();
            TxtReader.Close();

            return FileContent;
        }
        

        static public string FormatFooName()
        {
            //(new StackTrace()).GetFrame(1); // 0为本身的方法；1为调用方法
            var mtd = (new StackTrace()).GetFrame(1).GetMethod().Name;
            var cls = (new StackTrace()).GetFrame(1).GetMethod().ReflectedType.Name;
            return cls + "::" + mtd + "()";
        }

        ///// <summary>
        ///// 取数据库数据通用函数
        ///// </summary>
        //public static ArrayList SqlToList(string sqlMessage)
        //{
            
        //    try
        //    {
        //        var ds = DbHelper.Query(sqlMessage);
        //        return TableToList(ds);
        //    }
        //    catch (Exception ex)
        //    {
        //        throw new HtException(ObdFunction.FormatFooName() + " error: " + sqlMessage, ex);
        //    }
        //}
    }
}
