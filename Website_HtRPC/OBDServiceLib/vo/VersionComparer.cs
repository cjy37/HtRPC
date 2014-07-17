using System;
using System.Collections.Generic;
using System.Text;
using System.Collections;
using FluorineFx;
using OBDServiceLib.include;

namespace OBDServiceLib.vo
{
    class VersionComparer : IComparer
    {
        #region IComparer 成员

        public int Compare(object x, object y)
        {
            string versionX = (x as ASObject)["version"].ToString();
            string versionY = (y as ASObject)["version"].ToString();

            return Compare(versionX, versionY);
        }

        public int Compare(string x, string y)
        {
            string[] versionXList = x.Split('.');
            string[] versionYList = y.Split('.');
            int i = 0;

            try
            {
                for (i = 0; i < versionXList.Length && i < versionYList.Length; i++)
                {
                    var round = Convert.ToDecimal(versionXList[i]) - Convert.ToDecimal(versionYList[i]);
                    if (round == 0)
                        continue;
                    else
                        return round > 0 ? 1 : -1;
                }
            }
            catch (Exception ex)
            {
                throw new HtException(ObdFunction.FormatFooName() + "比较版本失败，版本1：" + x + " 版本2" + y + "位置：" + i, ex);
            }
            return versionXList.Length - versionYList.Length;
        }

        #endregion
    }
}
