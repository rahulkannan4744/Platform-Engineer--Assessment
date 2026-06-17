using Microsoft.AspNetCore.Mvc;
using Shared.Models;
using WorkApi.Services;

namespace WorkApi.Controllers;

[ApiController]
[Route("api/work")]
public class WorkController : ControllerBase
{
    private readonly IWorkQueueService _queueService;

    public WorkController(IWorkQueueService queueService)
    {
        _queueService = queueService;
    }

    [HttpGet]
    public IActionResult Get()
    {
        return Ok(new
        {
            Status = "Running",
            Queue = "work-items"
        });
    }

    [HttpPost]
    public async Task<IActionResult> Post(WorkItem item)
    {
        item.Id = Guid.NewGuid();
        item.CreatedUtc = DateTime.UtcNow;

        await _queueService.EnqueueAsync(item);

        return Accepted(item);
    }
}