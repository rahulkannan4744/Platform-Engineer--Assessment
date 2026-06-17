namespace Shared.Models;

public class WorkItem
{
    public Guid Id { get; set; }

    public string Name { get; set; } = string.Empty;

    public DateTime CreatedUtc { get; set; }

    public bool Processed { get; set; }
}