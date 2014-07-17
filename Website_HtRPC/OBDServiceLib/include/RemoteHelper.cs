using System;
using FluorineFx.Messaging.Services;
using FluorineFx.Messaging.Messages;
using FluorineFx.Messaging;


namespace OBDServiceLib.include
{

    public class RemoteHelper
    {
        /// <summary>
        /// 构造函数
        /// </summary>
        public RemoteHelper()
        {
            //初始化
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
            IService serviceHandler = messageBroker.GetService(remotingMessage);
            return serviceHandler.ServiceMessage(remotingMessage);
        }

        


    }
}
