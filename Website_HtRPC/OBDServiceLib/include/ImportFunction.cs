using System;
using System.Collections.Generic;
using System.Text;
using System.Web;
using System.Collections;
using System.Data.OleDb;
using System.Data;
using System.IO;
using System.Web.UI;
using System.Web.UI.WebControls;



namespace OBDServiceLib.include
{
    public class ImportFunction
    {

        private static string strConn = "Provider=Microsoft.Jet.OLEDB.4.0;Data Source={0};Extended Properties='Excel 8.0;HDR=YES;IMEX=1'"; 

        /// <summary>
        /// 
        /// </summary>
        /// <param name="filePath"></param>
        /// <returns></returns>
        static private OleDbConnection GetExcelConn(string filePath)
        {
            var tmpPath = HttpContext.Current.Server.MapPath(filePath);
            var conn = new OleDbConnection(strConn.Replace("{0}",tmpPath));
            conn.Open();
            return conn;
        }

        /// <summary>
        /// 获得Excel中的所有sheetname
        /// 如果只有一个，可用该sheetname直接导入
        /// 否则需要选择sheetname
        /// </summary>
        /// <param name="filepath">Excel文件的路径</param>
        /// <returns></returns>
        static public ArrayList ExcelSheetName(string filepath)
        {
            try
            {
                var al = new ArrayList();
                var conn = GetExcelConn(filepath);
                var sheetNames = conn.GetOleDbSchemaTable
                (OleDbSchemaGuid.Tables, new object[] { null, null, null, "TABLE" });
                conn.Close();
                foreach (DataRow dr in sheetNames.Rows)
                {
                    al.Add(dr[2]);
                }
                return al;
            }
            catch (Exception)
            {
                throw;
            }
        }

        /// <summary>
        /// 该方法实现从Excel中导出数据到DataSet中，其中filepath为Excel文件的绝对路径，sheetname为表示那个Excel表；
        /// </summary>
        /// <param name="filePath"></param>
        /// <param name="sheetname"></param>
        /// <returns></returns>
        static public DataTable Excel2Table(string filePath, string sheetname)
        {
            try
            {
                var tmpPath = HttpContext.Current.Server.MapPath(filePath);
                var strConn = "Provider=Microsoft.ACE.OLEDB.12.0;Data Source=" + HttpContext.Current.Server.MapPath(filePath) + ";Extended Properties=\"Excel 8.0;HDR=Yes;IMEX=1\";";
                var sqltxt = "select * from [" + sheetname + "]";
                var myCommand = new OleDbDataAdapter(sqltxt, strConn.Replace("{0}",tmpPath));
                var dt = new DataTable();
                myCommand.Fill(dt);
                return dt;
            }
            catch (Exception)
            {
                throw;
            }
            
        }

        /// <summary>
        /// 该方法实现将数据导入到Excel文件中，其中的DataTable dt就是你需要将数据写入到Excel中的数据；
        /// </summary>
        /// <param name="dt"></param>
        /// <param name="w"></param>
        static public void ExportExcel(DataTable dt, StreamWriter w)
        {
            try
            {
                for (var i = 0; i < dt.Columns.Count; i++)
                {
                    w.Write(dt.Columns[i]);
                    w.Write(' ');
                }
                w.Write(" ");

                foreach (DataRow dr in dt.Rows)
                {
                    var values = dr.ItemArray;
                    for (var i = 0; i < dt.Columns.Count; i++)
                    {
                        w.Write(values[i]);
                        w.Write(' ');
                    }
                    w.Write(" ");
                }
                w.Flush();
                w.Close();
            }
            finally 
            {
                w.Close();
            }
        }


        /// <summary>
        /// filename为Excel的名字，ToExcelGrid就是数据源，在此为DataGrid数据源；
        /// </summary>
        /// <param name="p"></param>
        /// <param name="filename"></param>
        /// <param name="toExcelGrid"></param>
        static public void ExportExcelFromDataGrid(System.Web.UI.Page p, string filename, Control toExcelGrid)
        {
            try
            {
                p.Response.Clear();
                p.Response.Buffer = true;
                p.Response.Charset = "utf-8";
                p.Response.AppendHeader("Content-Disposition", "attachment;filename=" + p.Server.UrlEncode(filename));
                p.Response.ContentEncoding = System.Text.Encoding.GetEncoding("utf-8");//设置输出流为简体中文   
                p.Response.ContentType = "application/ms-excel";//设置输出文件类型为excel文件。     
                p.EnableViewState = false;
                var myCItrad = new System.Globalization.CultureInfo("ZH-CN", true);
                var oStringWriter = new StringWriter(myCItrad);
                var oHtmlTextWriter = new HtmlTextWriter(oStringWriter);
                toExcelGrid.RenderControl(oHtmlTextWriter);
                p.Response.Write(oStringWriter.ToString());
                p.Response.End();
            }
            catch (Exception)
            {
                
                throw;
            }
            
        }

        /// <summary>
        /// 导入数据到数据集中
        /// </summary>
        /// <param name="path"></param>
        /// <param name="tableName"></param>
        /// <param name="tablename2">如果这个有就以他为表名，没有的话就以TableName</param>
        /// <returns></returns>
        static public DataTable InputExcel(string path, string tableName, string tablename2)
        {
            try
            {
                var conn = GetExcelConn(path);
                if (tablename2.Length > 0 && !tablename2.Equals(string.Empty))
                    tableName = tablename2;
                var strExcel = "select * from [" + tableName + "$]";
                var myCommand = new OleDbDataAdapter(strExcel, conn);
                var dt = new DataTable();
                myCommand.Fill(dt);
                conn.Close();
                return dt;
            }
            finally
            {
            }
        }

        /// <summary>
        /// 上传excel文件到指定目录
        /// </summary>
        /// <param name="file">excel文件</param>
        /// <param name="filePath">指定目录</param>
        /// <returns>filePath + 新的文件名</returns>
        static public string UploadFile(HttpPostedFileBase file, string filePath)
        {
            try
            {
                filePath = Path.GetDirectoryName(filePath);
                var path = HttpContext.Current.Server.MapPath(filePath);
                if (!Directory.Exists(path))
                {
                    Directory.CreateDirectory(path);
                }
                if (file != null && file.ContentLength > 0)
                {
                    string[] stringExecSpplit = { "," };
                    string[] stringFileSpplit = { "." };
                    var exeFileList = "xls,rar,zip,bin,bios,jpg,gif,png,bmp,swf".Split(stringExecSpplit,
                                                            StringSplitOptions.RemoveEmptyEntries);
                    var fileExtList = file.FileName.ToLower().Split(stringFileSpplit,
                                                              StringSplitOptions.RemoveEmptyEntries);
                    var fileExt = fileExtList[fileExtList.Length - 1].ToLower();
                    var isAllowFile = false;

                    foreach (var s in exeFileList)
                    {
                        if (fileExt != s) continue;
                        isAllowFile = true;
                        break;
                    }
                    if (isAllowFile)
                    {
                        try
                        {
                            var now = DateTime.Now;
                            var fileName = "" + now.Year + now.Month + now.Day + now.Hour + now.Minute + now.Second +
                                           now.Millisecond + "." + fileExt;
                            var savePath = path + "\\" + fileName;
                            file.SaveAs(savePath);
                            return filePath + "\\" +fileName;
                        }
                        catch (Exception)
                        {
                            throw new IOException("Pub/Error:" + "请确认服务器路径'" + path + "'是否存在", 80800);
                        }
                    }
                    throw new IOException("Pub/Error:" + "不允许上传的文件类型", 80800);
                }
                
                throw new IOException("Pub/Error:" + "请至少选择一个文件上传", 80800);
            }
            finally
            {
            }
        }

        /// <summary>
        /// 上传excel文件到指定目录
        /// </summary>
        /// <param name="file">excel文件</param>
        /// <param name="filePath">指定目录</param>
        /// <returns>filePath + 新的文件名</returns>
        static public string UploadFile(HttpPostedFile file, string filePath)
        {
            try
            {
                filePath = Path.GetDirectoryName(filePath);
                var path = HttpContext.Current.Server.MapPath(filePath);
                if (!Directory.Exists(path))
                {
                    Directory.CreateDirectory(path);
                }
                if (file != null && file.ContentLength > 0)
                {
                    string[] stringExecSpplit = { "," };
                    string[] stringFileSpplit = { "." };
                    var exeFileList = "xls,rar,zip,bin,bios,jpg,gif,png,bmp,swf".Split(stringExecSpplit,
                                                            StringSplitOptions.RemoveEmptyEntries);
                    var fileExtList = file.FileName.ToLower().Split(stringFileSpplit,
                                                              StringSplitOptions.RemoveEmptyEntries);
                    var fileExt = fileExtList[fileExtList.Length - 1].ToLower();
                    var isAllowFile = false;

                    foreach (var s in exeFileList)
                    {
                        if (fileExt != s) continue;
                        isAllowFile = true;
                        break;
                    }
                    if (isAllowFile)
                    {
                        try
                        {
                            var now = DateTime.Now;
                            var fileName = "" + now.Year + now.Month + now.Day + now.Hour + now.Minute + now.Second +
                                           now.Millisecond + "." + fileExt;
                            var savePath = path + "\\" + fileName;
                            file.SaveAs(savePath);
                            return filePath + "\\" + fileName;
                        }
                        catch (Exception)
                        {
                            throw new IOException("Pub/Error:" + "请确认服务器路径'" + path + "'是否存在", 80800);
                        }
                    }
                    throw new IOException("Pub/Error:" + "不允许上传的文件类型", 80800);
                }

                throw new IOException("Pub/Error:" + "请至少选择一个文件上传", 80800);
            }
            finally
            {
            }
        }

        public static string FromUnicodeByteArray(byte[] characters) 
        {
            UTF8Encoding encoding = new UTF8Encoding(); 
            string constructedString = encoding.GetString(characters); 
            return (constructedString); 
        } 

    }
}
