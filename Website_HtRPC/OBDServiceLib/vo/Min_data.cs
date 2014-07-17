using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace OBDServiceLib.vo
{
    public  class Min_data
    {
        /// <summary>
        /// 汽车id
        /// </summary>
        public int id;
        /// <summary>
        /// 工况时间
        /// </summary>
        public DateTime d_time;
        /// <summary>
        /// 工况类型
        /// </summary>
        public string code;

        public float ave;
    }
}
