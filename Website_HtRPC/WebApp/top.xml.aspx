<%@ Page Language="C#" AutoEventWireup="true" %>
<%@ Import Namespace="System.Runtime.InteropServices" %>
<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Reflection" %>
<%@ Import Namespace="System.Collections" %>

<script runat="server">
    #region Assistance Class
    public class SystemInfo
    {
        [DllImport("kernel32", CharSet = CharSet.Auto, SetLastError = true)]
        internal static extern void GetSystemInfo(ref CpuInfo cpuinfo);
        [DllImport("kernel32", CharSet = CharSet.Auto, SetLastError = true)]
        internal static extern void GlobalMemoryStatus(ref MemoryInfo meminfo);

        [StructLayout(LayoutKind.Sequential)]
        public struct CpuInfo
        {
            public uint dwOemId;
            public uint dwPageSize;
            public uint lpMinimumApplicationAddress;
            public uint lpMaximumApplicationAddress;
            public uint dwActiveProcessorMask;
            public uint dwNumberOfProcessors;
            public uint dwProcessorType;
            public uint dwAllocationGranularity;
            public uint dwProcessorLevel;
            public uint dwProcessorRevision;
        }

        [StructLayout(LayoutKind.Sequential)]
        public struct MemoryInfo
        {
            public uint dwLength;
            public uint dwMemoryLoad;
            public uint dwTotalPhys;
            public uint dwAvailPhys;
            public uint dwTotalPageFile;
            public uint dwAvailPageFile;
            public uint dwTotalVirtual;
            public uint dwAvailVirtual;
        }

        public static MemoryInfo Memory
        {
            get
            {
                MemoryInfo obj = new MemoryInfo();
                GlobalMemoryStatus(ref obj);
                return obj;
            }
        }

        public static CpuInfo Cpu
        {
            get
            {
                CpuInfo obj = new CpuInfo();
                GetSystemInfo(ref obj);
                return obj;
            }
        }

    }
    #endregion

    private static System.Collections.Generic.Dictionary<string, string> paramCached = new System.Collections.Generic.Dictionary<string, string>();

    private static string getCached(string key)
    {
        if (paramCached.ContainsKey(key))
        {
            return paramCached[key];
        }
        return null;
    }

    private static void setCached(string key, string value)
    {
        if (paramCached.ContainsKey(key))
        {
            paramCached[key] = value;
            return;
        }
        paramCached.Add(key, value);
    }
    
    
    
    #region Get Information Function

    private void GetSystemInfo()
    {
        if (getCached("ServerName") == null)
        {
            setCached("ServerName",Server.MachineName);
            setCached("ServerIP",Request.ServerVariables["LOCAl_ADDR"]);
            setCached("ServerDomain",Request.ServerVariables["Server_Name"]);
            setCached("ServerPort",Request.ServerVariables["Server_Port"]);
            
            setCached("ServerVersion",Request.ServerVariables["Server_SoftWare"]);
            setCached("FilePath",Request.FilePath);
            setCached("PhysicalPath",Request.PhysicalPath);
            setCached("ApplicationPath",Request.ApplicationPath);
            setCached("PhysicalApplicationPath", Request.PhysicalApplicationPath);

            //	平台信息
            OperatingSystem os = Environment.OSVersion;
            string text = string.Empty;
            if ((int)os.Platform > 3)
            {
                string name = "/proc/version";
                if (File.Exists(name))
                {
                    using (StreamReader reader = new StreamReader(name))
                    {
                        text = reader.ReadToEnd().Trim();
                    }
                }
            }
            
            setCached("OS", Request.ServerVariables["Server_SoftWare"]);
            setCached("OSVersion", os.ToString());
            setCached("DotNetFramworkRunTime", Environment.Version.ToString());
            setCached("DotNetCulture", System.Globalization.CultureInfo.InstalledUICulture.EnglishName);
            setCached("ScriptTimeout", Server.ScriptTimeout.ToString());
        }
        //DataTable table = GenerateDataTable("系统信息");
        //	服务器信息
        Assign("ServerName", getCached("ServerName"));
        Assign("ServerIP", getCached("ServerIP"));
        Assign("ServerDomain", getCached("ServerDomain"));
        Assign("ServerPort", getCached("ServerPort"));
        //	站点信息
        Assign("ServerVersion", getCached("ServerVersion"));
        //	站点路径信息
        Assign("FilePath", getCached("FilePath"));//虚拟路径
        Assign("PhysicalPath", getCached("PhysicalPath"));//物理路径
        Assign("ApplicationPath", getCached("ApplicationPath"));//虚拟站点路径
        Assign("PhysicalApplicationPath", getCached("PhysicalApplicationPath"));//物理站点路径

        Assign("OS", getCached("OS"));
        Assign("OSVersion", getCached("OSVersion"));
        Assign("DotNetFramworkRunTime", getCached("DotNetFramworkRunTime"));
        Assign("DotNetCulture", getCached("DotNetCulture"));
        Assign("ServerDateTime", (DateTime.Now.Ticks/10000).ToString());//服务器时间（ms）
        Assign("ServerRunTime", Environment.TickCount.ToString());//服务器运行时间（ms）
        Assign("ScriptTimeout", getCached("ScriptTimeout"));//服务器脚本超时（s）
        Assign("LoadAvg", GetLoadAvg());
    }

	private String GetRunTimes(int t)
	{
		string ext = "";
		if (t < 0)
		{
			ext = "-";
			t = Math.Abs(t);
		}
		string ret = "";
	    int str = t / 1000;
		int min = str / 60;
		int hours = min / 60;
		int days = (int)System.Math.Floor(hours / 24.0);
		hours = (int)System.Math.Floor(hours - (days * 24.0));
		min = (int)System.Math.Floor(min - (days * 60 * 24) - (hours * 60.0));
		if (days != 0) {ret = days+"天";}
		if (hours != 0) {ret += hours+"小时";}
		ret += min+"分钟";
		return ext+ret;
	}
	
	//获取磁盘信息
    private void GetSystemStorageInfo_DriveInfo()
    {
        try
        {
            Type typeDriveInfo = Type.GetType("System.IO.DriveInfo");
            MethodInfo get_drives = typeDriveInfo.GetMethod("GetDrives");
            object result = get_drives.Invoke(null, null);

            foreach (object o in (IEnumerable)result)
            {
                try
                {
                    //  Use reflection to call DriveInfo.GetProperties() to make 1.x compiler don't complain.
                    PropertyInfo[] props = typeDriveInfo.GetProperties();
                    bool is_ready = (bool)typeDriveInfo.GetProperty("IsReady").GetValue(o, null);
                    string name = string.Empty;
                    string volume_label = string.Empty;
                    string drive_format = string.Empty;
                    string drive_type = string.Empty;
                    ulong total_free_space = 0;
                    ulong total_space = 0;
                    foreach (PropertyInfo prop in props)
                    {
                        switch (prop.Name)
                        {
                            case "Name":
                                name = (string)prop.GetValue(o, null);
                                break;
                            case "VolumeLabel":
                                if (is_ready)
                                    volume_label = (string)prop.GetValue(o, null);
                                break;
                            case "DriveFormat":
                                if (is_ready)
                                    drive_format = (string)prop.GetValue(o, null);
                                break;
                            case "DriveType":
                                drive_type = prop.GetValue(o, null).ToString();
                                break;
                            case "TotalFreeSpace":
                                if (is_ready)
                                    total_free_space = (ulong)(long)prop.GetValue(o, null);
                                break;
                            case "TotalSize":
                                if (is_ready)
                                    total_space = (ulong)(long)prop.GetValue(o, null);
                                break;
                        }
                    }

                    string label = string.Empty;
                    string size = string.Empty;

                    if (is_ready)
                    {
                        label = name;// string.Format("{0} - <{1}> [{2}] - {3,-10}", name, volume_label, drive_format, drive_type);
                        if (total_space > 0 && total_space != ulong.MaxValue && total_space != int.MaxValue)
                        {
                            size = string.Format("{2},{0},{1}", total_free_space.ToString(), total_space.ToString(),
                                GetPercentage(total_space - total_free_space, total_space));//使用率 {2} % (空闲 {0} / 共 {1})
                            Assign(label, size);
                        }
                    }
                    //else
                    //{
                    //    label = string.Format("{0} {1,-10}", name, drive_type);
                    //}

                    
                }
                catch (Exception) { }
            }
        }
        catch (Exception) { }
    }

    
    
    //获取磁盘信息
    private void GetSystemStorageInfo()
    {
        //DataTable table = GenerateDataTable("磁盘信息");

        try { Assign("LogicalDrives", string.Join(", ", Directory.GetLogicalDrives())); }
        catch (Exception) { }

        if (Environment.Version.Major >= 2)
        {
            GetSystemStorageInfo_DriveInfo();
        }


        //return table;
    }
    
    private void GetSystemMemoryInfo_proc()
    {
        string name = "/proc/meminfo";
        if (File.Exists(name))
        {
            using (StreamReader reader = new StreamReader(name, Encoding.ASCII))
            {
                Hashtable ht = new Hashtable();
                string line = string.Empty;
                while ((line = reader.ReadLine()) != null)
                {
                    string[] item = line.Split(":".ToCharArray());
                    if (item.Length == 2)
                    {
                        string k = item[0].Trim();
                        string v = item[1].Trim();
                        ht.Add(k, v);
                    }
                }
//Response.Write((string)ht["MemTotal"]);
                ulong MemTotal = Convert.ToUInt64(((string)ht["MemTotal"]).Replace(" kB", "")) * 1024;
                ulong MemFree = Convert.ToUInt64(((string)ht["MemFree"]).Replace(" kB", "")) * 1024;
                ulong MemCached = Convert.ToUInt64(((string)ht["Cached"]).Replace(" kB", "")) * 1024;
                ulong MemBuffers = Convert.ToUInt64(((string)ht["Buffers"]).Replace(" kB", "")) * 1024;
                ulong SwapTotal = Convert.ToUInt64(((string)ht["SwapTotal"]).Replace(" kB", "")) * 1024;
                ulong SwapFree = Convert.ToUInt64(((string)ht["SwapFree"]).Replace(" kB", "")) * 1024;
                
                ulong memRealUsed = MemTotal - MemFree - MemCached - MemBuffers;//真实内存使用
                ulong memRealFree = MemTotal - memRealUsed;//真实空闲
                double memRealPercent = GetPercentage(memRealUsed, MemTotal);//真实内存使用率
                double memPercent = GetPercentage(MemTotal - MemFree, MemTotal);//内存使用率
                double memCachedPercent = GetPercentage(MemCached, MemTotal);//Cached内存使用率
                double memSwapPercent = GetPercentage(SwapTotal-SwapFree, SwapTotal);//Swap使用率

                Assign("PhysicalMemory", string.Format("{0},{1},{2},{3}", MemTotal.ToString(),
                    (MemTotal - MemFree).ToString(),
                    MemFree.ToString(),
                    memPercent));//共 {0} , 已用 {1} , 空闲 {2} , 使用率 {3} %
                Assign("CacheMemory", string.Format("{0},{1},{2}", MemCached.ToString(),
                    memCachedPercent,
                    MemBuffers.ToString()));//为 {0} , 使用率 {1} % | Buffers缓冲为 {2}
                Assign("RealMemory", string.Format("{0},{1},{2}", memRealUsed.ToString(),
                    memRealFree.ToString(),
                    memRealPercent));//使用 {0} , 空闲 {1} , 使用率 {2} %
                Assign("SwapPartition", string.Format("{0},{1},{2},{3}", SwapTotal.ToString(),
                    (SwapTotal-SwapFree).ToString(),
                    SwapFree.ToString(),
                    memSwapPercent));//共 {0} , 已使用 {1} , 空闲 {2} , 使用率 {3} %
            }
        }
    }
    
    //获取内存信息
    private void GetSystemMemoryInfo()
    {
        //DataTable table = GenerateDataTable("内存信息"); ;
        //Assign("当前工作集", FormatNumber((ulong)Environment.WorkingSet));
        try
        {
            if ((int)Environment.OSVersion.Platform > 3)
            {
                GetSystemMemoryInfo_proc();
            }
        }
        catch (Exception) { }
        //return table;
    }


    private void GetNetworkInfo()
    {
        //DataTable table = GenerateDataTable("网络信息");
        //try
        {
            if ((int)Environment.OSVersion.Platform > 3)
            {
                GetNetworkInfo_proc();
            }
        }
        //catch (Exception) { }
        //return table;
    }

    private string GetLoadAvg()
    {
        string ret = "";
        string name = "/proc/loadavg";
        if (File.Exists(name))
        {
            using (StreamReader reader = new StreamReader(name, Encoding.ASCII))
            {
                ret = reader.ReadToEnd();
            }
        }
        string[] ret0 = ret.Split(" ".ToCharArray());
        return ret0[0] + " " + ret0[1] + " " + ret0[2] + " " + ret0[3];
    }
    
    private void GetNetworkInfo_proc()
    {

        string name = "/proc/net/dev";
        if (File.Exists(name))
        {
            using (StreamReader reader = new StreamReader(name, Encoding.ASCII))
            {
                string line = string.Empty;
                int i = 0;
                while ((line = reader.ReadLine()) != null)
                {
                    if (line.Trim().Length == 0)
                    {
                        continue;
                    }
                    //eth0: 5112682 8170 0 0 0 0 0 0 2622415 6314 0 0 0 0 0 0
                    string ret = RegexHelper.Match(line, @"([^\s]+):[\s]{0,}(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)", "$1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12");

                    string[] item = ret.Split(",".ToCharArray());
                    if (item.Length > 9)
                    {
//Response.Write(ret+"<br/>");//continue;
                        string key = item[0].Trim();

                        string sNetInputPk = item[2].Trim();
                        string sNetOutPk = item[10].Trim();
                        string sNetInputByte = "" + item[1].Trim();//(bytes)
                        string sNetOutByte = "" + item[9].Trim();//(bytes)
                        Assign(key, string.Format("{0},{1},{2},{3}", sNetInputByte, sNetOutByte, sNetInputPk, sNetOutPk));//接收 {0}, 发送 {1}, 接收包 {2}, 发送包 {3}
                    }
                    i++;
                }
            }
        }
    }

    
    
    //获取CPU信息
    private void GetSystemProcessorInfo_proc()
    {
        string name = "/proc/cpuinfo";
        if (File.Exists(name))
        {
            using (StreamReader reader = new StreamReader(name, Encoding.ASCII))
            {
                ArrayList processors = new ArrayList();
                Hashtable ht = new Hashtable();
                string line = string.Empty;
                while ((line = reader.ReadLine()) != null)
                {
                    if (line.Trim().Length == 0)
                    {
                        processors.Add(ht);
                        ht = new Hashtable();
                    }
                    string[] item = line.Split(":".ToCharArray());
                    if (item.Length == 2)
                    {
                        string k = item[0].Trim();
                        string v = item[1].Trim();
                        ht.Add(k, v);
                    }
                }
                int procNum = processors.Count;
                foreach (Hashtable processor in processors)
                {
                    string v = string.Format("{0}({4}核) | 频率:{1} | 二级缓存:{2} | Bogomips:{3}", processor["model name"],
											 (processor["cpu MHz"] != null) ? string.Format("{0} MHz", processor["cpu MHz"]) : string.Empty,
                                             processor["cache size"],
                                             processor["bogomips"],
                                             procNum);
                    Assign("processor", v);
                    break;
                }
            }
        }
    }

    private static ArrayList LastProcessors;
    //获取CPU信息
    private void GetSystemProcessorUse_proc()
    {
        string name = "/proc/stat";
        if (File.Exists(name))
        {
            using (StreamReader reader = new StreamReader(name, Encoding.ASCII))
            {
                ArrayList processors = new ArrayList();
                Hashtable ht = new Hashtable();
                Hashtable ht2 = new Hashtable();
                string line = string.Empty;
                while ((line = reader.ReadLine()) != null)
                {
                    string ret = RegexHelper.Match(line, @"(cpu[0-9]?)[\s]+([0-9]+)[\s]+([0-9]+)[\s]+([0-9]+)[\s]+([0-9]+)[\s]+([0-9]+)[\s]+([0-9]+)[\s]+([0-9]+)","$1,$2,$3,$4,$5,$6,$7,$8");
                    string[] item = ret.Split(",".ToCharArray());
                    if (item.Length > 7)
                    {
                        ht = new Hashtable();
                        ht["key"] = item[0].Trim();
                        ht["USER"] = (Convert.ToInt32(item[1].Trim()));
                        ht["NICE"] = (Convert.ToInt32(item[2].Trim()));
                        ht["SYSTEM"] = (Convert.ToInt32(item[3].Trim()));
                        ht["IDLE"] = (Convert.ToInt32(item[4].Trim()));
                        ht["IOWAIT"] = (Convert.ToInt32(item[5].Trim()));
                        ht["IRQ"] = (Convert.ToInt32(item[6].Trim()));
                        ht["SOFTIRQ"] = (Convert.ToInt32(item[7].Trim()));
                        processors.Add(ht);
                    }
                    if (RegexHelper.TestHasMatch(line, "procs_running"))
                    {
                        ht2["procs_running"] = line.Replace("procs_running ","");
                    }
                    if (RegexHelper.TestHasMatch(line, "procs_blocked"))
                    {
                        ht2["procs_blocked"] = line.Replace("procs_blocked ","");
                    }
                }
                if (null == LastProcessors)
                {
                    LastProcessors = processors;
                    System.Threading.Thread.Sleep(1000);
                    GetSystemProcessorUse_proc();
                    return;
                }

                string tmp0 = "";
                string tmp1 = "";
                int length = processors.Count;
                double cpuUsages = 0;
                Assign("cpuNum", (length-1).ToString());
                for (int i = 0; i < length; i++)
                {
                    Hashtable cpu2 = (Hashtable)processors[i];
                    Hashtable cpu1 = (Hashtable)LastProcessors[i];
                    int cpu2_total = (int)cpu2["USER"] + (int)cpu2["NICE"] + (int)cpu2["SYSTEM"] + (int)cpu2["IDLE"] + (int)cpu2["IOWAIT"] + (int)cpu2["IRQ"] + (int)cpu2["SOFTIRQ"];
                    int cpu1_total = (int)cpu1["USER"] + (int)cpu1["NICE"] + (int)cpu1["SYSTEM"] + (int)cpu1["IDLE"] + (int)cpu1["IOWAIT"] + (int)cpu1["IRQ"] + (int)cpu1["SOFTIRQ"];
                    double total = (double)(cpu2_total - cpu1_total);
                    double usage = total - ((double)((int)cpu2["IDLE"] - (int)cpu1["IDLE"]));
                    double cpuUsage = GetPercentage(usage, total);
					cpuUsages += cpuUsage;
                    if (i == 0)
                    {
                        tmp0 = cpuUsage + " % ";
                        Assign("cpuUsages", cpuUsage.ToString("0.##"));
                    }
                    else
                    {
                        if (tmp1.Length > 0)
                        {
                            tmp1 += ", ";
                        }
                        tmp1 += cpu2["key"] + " " + cpuUsage + "%";
                        Assign((string)cpu2["key"], cpuUsage.ToString("0.##"));
                    }
                    
                }
                Assign("procs_running", (string)ht2["procs_running"]);//当前运行队列的任务的数目
                Assign("procs_blocked", (string)ht2["procs_blocked"]);//当前被阻塞的任务的数目
                LastProcessors = processors;
            }
        }
    }
    
    //获取CPU信息
    private void GetSystemProcessorInfo()
    {
        try
        {
            if ((int)Environment.OSVersion.Platform > 3)
            {
                GetSystemProcessorInfo_proc();
                GetSystemProcessorUse_proc();
            }
        }
        catch (Exception) { }
    }

    //获取服务器参数
    private void GetServerVariables()
    {
        foreach (string key in Request.ServerVariables.AllKeys)
        {
            Assign(key, Request.ServerVariables[key]);
        }
    }
    
    //获取环境变量
    private void GetEnvironmentVariables()
    {
        foreach (DictionaryEntry de in System.Environment.GetEnvironmentVariables())
        {
            Assign(de.Key.ToString(), de.Value.ToString());
        }
    }

    


    private void GetSessionInfo()
    {
        Assign("Session Count", Session.Contents.Count.ToString());
        Assign("Application Count", Application.Contents.Count.ToString());
    }
    private void GetRequestHeaderInfo()
    {
        foreach (string key in Request.Headers.AllKeys)
        {
            Assign(key, Request.Headers[key]);
        }
    }

    #endregion

    #region Helper Methods

    private double GetPercentage(double value, double total)
    {
        return (int)(value * 10000.0 / total) / 100.0;
    }
    
    //单位转换
    private string formatsize(double size)
    {
        string[] danwei = new string[] { " B ", " K ", " M ", " G ", " T " };
        System.Collections.Generic.List<int> allsize = new System.Collections.Generic.List<int>();
        int i = 0;
        string fsize = "";

        for (i = 0; i < 4; i++)
        {
            if (Math.Floor(size / Math.Pow(1024, i)) == 0) { break; }
        }
        double[] allsize1 = new double[i + 1];
        allsize1[i] = 0;
        for (int l = i - 1; l >= 0; l--)
        {
            allsize1[l] = Math.Floor(size / Math.Pow(1024, l));
            allsize.Add((int)(allsize1[l] - allsize1[l + 1] * 1024));
        }

        int len = allsize.Count;

        for (int j = 0; j < len; j++)
        {
            int strlen = 4 - allsize[j].ToString().Length;
            string ret = "";
            if (strlen == 1)
                ret = "<font color='#eee'>0</font>" + allsize[j];
            else if (strlen == 2)
                ret = "<font color='#eee'>00</font>" + allsize[j];
            else if (strlen == 3)
                ret = "<font color='#eee'>000</font>" + allsize[j];
            else
                ret = "<font color='#eee'>0000</font>";
            fsize = fsize + ret + danwei[len - 1 - j];
        }
        return fsize;
    }
    
    private string FormatNumber(ulong value)
    {
        if (value < 4*1024){
            return string.Format("{0} Bytes", value);
        }
        else if (value < (long)4 * 1024 * 1024)
        {
            return string.Format("{0} KB", (value / (double)((long)1024)).ToString("N"));
        }
        else if (value < (long)4 * 1024 * 1024 * 1024)
        {
            return string.Format("{0} MB", (value / (double)((long)1024 * 1024)).ToString("N"));
        }
        else if (value < (long)4 * 1024 * 1024 * 1024 * 1024)
        {
            return string.Format("{0} GB", (value / (double)((long)1024 * 1024 * 1024)).ToString("N"));
        }
        else
        {
            return string.Format("{0} TB", (value / (double)((long)1024 * 1024 * 1024 * 1024)).ToString("N"));
        }
    }

    private bool TestObject(string progID)
    {
        try
        {
            Server.CreateObject(progID);
            return true;
        }
        catch (Exception)
        {
            return false;
        }
    }

	private void Assign(string name, string value)
    {
		Response.Write("<item id=\""+Server.HtmlEncode(name)+"\">"+Server.HtmlEncode(value)+"</item>");
    }	

    #endregion

    protected void Page_Load(object sender, EventArgs e)
    {
        long begin = DateTime.Now.Ticks;
        
        Response.ContentType = "text/xml";
        Response.ContentEncoding = Encoding.UTF8;
        
		Response.Write("<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<root>\n");

        Response.Write("<SystemInfo>");
		GetSystemInfo();
        Response.Write("</SystemInfo>");

        Response.Write("<ProcessorInfo>");
		GetSystemProcessorInfo();
        Response.Write("</ProcessorInfo>");

        Response.Write("<MemoryInfo>");
		GetSystemMemoryInfo();
        Response.Write("</MemoryInfo>");

        Response.Write("<StorageInfo>");
		GetSystemStorageInfo();
        Response.Write("</StorageInfo>");


        Response.Write("<NetworkInfo>");
		GetNetworkInfo();
        Response.Write("</NetworkInfo>");
        
		long offset = DateTime.Now.Ticks - begin;
        //Assign("scriptRunTime", (offset / 10000) + "");//ms
        Response.Write("<scriptRunTime>" + (offset / 10000) + "</scriptRunTime>\n");
        
		Response.Write("</root>");
    }

    /// <summary>
    /// 正则表达式帮助类
    /// </summary>
    public class RegexHelper
    {
        /// <summary>
        /// 替换字符串
        /// </summary>
        /// <param name="input">输入的字符串</param>
        /// <param name="pattern">正则表达式</param>
        /// <param name="matchString">新字符串</param>
        /// <returns></returns>
        public static string Replace(string input, string pattern, string matchString)
        {
            var reg = new Regex(pattern, RegexOptions.IgnoreCase);
            return reg.Replace(input, matchString);
        }

        /// <summary>
        /// 测试字符串是否包含规则
        /// </summary>
        /// <param name="input">输入的字符串</param>
        /// <param name="pattern">正则表达式</param>
        /// <returns></returns>
        public static bool TestHasMatch(string input, string pattern)
        {
            var reg = new Regex(pattern, RegexOptions.IgnoreCase);
            var ma = reg.Match(input);
            return ma.Success;
        }

        /// <summary>
        /// 根据正则表达式取规则的部分
        /// </summary>
        /// <param name="input">输入的字符串</param>
        /// <param name="pattern">正则表达式</param>
        /// <param name="matchString">规则的部分，形如$1...</param>
        /// <returns></returns>
        public static string Match(string input, string pattern, string matchString)
        {
            string ret = input;
            var reg = new Regex(pattern, RegexOptions.IgnoreCase);
            var ma = reg.Match(input);
            if (ma.Success)
                ret = string.IsNullOrEmpty(matchString) ? ma.Value : ma.Result(matchString);
            return ret;
        }


        public static string[] Split(string input, string pattern)
        {
            var reg = new Regex(pattern, RegexOptions.IgnoreCase);
            return reg.Split(input);
        }
    }
    
</script>
