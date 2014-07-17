using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace OBDServiceLib.vo
{
    public class Trip_data
    {
        /// <summary>
        /// 汽车id
        /// </summary>
        public int id;
        /// <summary>
        /// 保养信息
        /// </summary>
        public string isReminder;
        /// <summary>
        /// 总公里数
        /// </summary>
        public float totalMiles;

    }
}
