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
using FluorineFx;
using FluorineFx.Context;
using FluorineFx.IO;
using FluorineFx.AMF3;
using System.Data;
using System.Data.SqlClient;
using System.Reflection;
using FluorineFx.Json;
using OBDServiceLib.include;
using Htxw.AMFRemoting;
using FluorineFx.Messaging.Services;
using FluorineFx.Messaging.Messages;
using FluorineFx.Messaging;


namespace OBDServiceLib.RemoteInterface
{
    /// <summary>
    ///  系统信息接口
    /// </summary>
    [RemotingService("Fluorine SysInfoInterface service")]
    public class RemoteHelper
    {
        /// <summary>
        /// 构造函数
        /// </summary>
        public RemoteHelper()
        {
            //初始化
            //_DBclass.StrConn(ObdConfig.DBConnString);
        }

        public static object invokeService(string service, string operation, object[] args)
        {
            MessageBroker messageBroker = MessageBroker.GetMessageBroker(null);

            RemotingMessage remotingMessage = new RemotingMessage();
            remotingMessage.source = service;
            remotingMessage.operation = operation;
            string destinationId = messageBroker.GetDestinationId(remotingMessage);
            remotingMessage.destination = destinationId;
            remotingMessage.body = args;
            remotingMessage.timestamp = Environment.TickCount;
            //IMessage response = messageBroker.RouteMessage(remotingMessage);
            IService serviceHandler = messageBroker.GetService(remotingMessage);
            object result = serviceHandler.ServiceMessage(remotingMessage);
            return result;
        }

        


    }
}
