using Azure.Messaging.ServiceBus;

namespace WorkerService.Services;

public class QueueWorker : BackgroundService
{
    private readonly ServiceBusProcessor _processor;
    private readonly ILogger<QueueWorker> _logger;

    public QueueWorker(
        ServiceBusClient client,
        ILogger<QueueWorker> logger)
    {
        _logger = logger;

        _processor = client.CreateProcessor("work-items");
    }

    protected override async Task ExecuteAsync(
        CancellationToken stoppingToken)
    {
        _processor.ProcessMessageAsync += HandleMessage;
        _processor.ProcessErrorAsync += HandleError;

        await _processor.StartProcessingAsync(
            stoppingToken);
    }

    private async Task HandleMessage(
        ProcessMessageEventArgs args)
    {
        _logger.LogInformation("Message received");

        await args.CompleteMessageAsync(
            args.Message);
    }

    private Task HandleError(
        ProcessErrorEventArgs args)
    {
        _logger.LogError(
            args.Exception,
            "ServiceBus Error");

        return Task.CompletedTask;
    }
}