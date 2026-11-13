using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Evdekiler.Pantry.Api.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddSourceShoppingItemId : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<Guid>(
                name: "SourceShoppingItemId",
                table: "PantryItems",
                type: "uuid",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_PantryItems_SourceShoppingItemId",
                table: "PantryItems",
                column: "SourceShoppingItemId",
                unique: true,
                filter: "\"SourceShoppingItemId\" IS NOT NULL");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_PantryItems_SourceShoppingItemId",
                table: "PantryItems");

            migrationBuilder.DropColumn(
                name: "SourceShoppingItemId",
                table: "PantryItems");
        }
    }
}
