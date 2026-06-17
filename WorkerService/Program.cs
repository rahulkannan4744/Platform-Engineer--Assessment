using Azure.Messaging.ServiceBus;
using WorkerService.Services;

var builder = Host.CreateApplicationBuilder(args);

builder.Services.AddSingleton(
    new ServiceBusClient(
        builder.Configuration["ServiceBusConnection"]
    ));

builder.Services.AddHostedService<QueueWorker>();

var host = builder.Build();

host.Run();