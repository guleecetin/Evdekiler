using Evdekiler.Identity.Api.Entities;
using Microsoft.EntityFrameworkCore;

namespace Evdekiler.Identity.Api.Data;

public class AppDbContext(DbContextOptions<AppDbContext> options) : DbContext(options)
{
    public DbSet<User> Users => Set<User>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<User>(entity =>
        {
            entity.HasKey(u => u.Id);

            entity.Property(u => u.Email).HasMaxLength(256).IsRequired();
            entity.HasIndex(u => u.Email).IsUnique();

            entity.Property(u => u.DisplayName).HasMaxLength(100).IsRequired();
            entity.Property(u => u.PasswordHash).IsRequired();
        });
    }
}