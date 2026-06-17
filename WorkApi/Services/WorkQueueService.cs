using System.Text.Json;
using Azure.Messaging.ServiceBus;
using Shared.Models;

namespace WorkApi.Services;

public class WorkQueueService : IWorkQueueService
{
    private readonly ServiceBusClient _client;
    private readonly IConfiguration _configuration;

    public WorkQueueService(
        ServiceBusClient client,
        IConfiguration configuration)
    {
        _client = client;
        _configuration = configuration;
    }

    public async Task EnqueueAsync(WorkItem item)
    {
        var queueName =
            _configuration["ServiceBus:QueueName"];

        var sender =
            _client.CreateSender(queueName);

        var payload =
            JsonSerializer.Serialize(item);

        await sender.SendMessageAsync(
            new ServiceBusMessage(payload));
    }
}