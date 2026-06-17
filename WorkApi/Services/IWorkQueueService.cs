using Shared.Models;

namespace WorkApi.Services;

public interface IWorkQueueService
{
    Task EnqueueAsync(WorkItem item);
}