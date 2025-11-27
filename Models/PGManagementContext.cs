using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Data.Entity;
using PG_Management.Models;


namespace PG_Management.Models
{
    public class PGManagementContext : DbContext
    {
        public PGManagementContext() : base("name=EasyPG") { }

        public DbSet<PGListingModel> PGListings { get; set; }
        public DbSet<UserModel> Users { get; set; }
    }
}