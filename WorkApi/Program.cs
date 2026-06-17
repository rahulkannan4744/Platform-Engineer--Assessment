using Azure.Identity;
using Azure.Messaging.ServiceBus;
using WorkApi.Services;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();
builder.Services.AddHealthChecks();

// builder.Services.AddApplicationInsightsTelemetry();

builder.Services.AddSingleton<ServiceBusClient>(_ =>
{
    var namespaceName =
        builder.Configuration["ServiceBus:Namespace"];

    return new ServiceBusClient(
        namespaceName,
        new DefaultAzureCredential());
});

builder.Services.AddScoped<IWorkQueueService, WorkQueueService>();

var app = builder.Build();

app.MapControllers();
app.MapHealthChecks("/health/live");
app.MapHealthChecks("/health/ready");

app.Run();