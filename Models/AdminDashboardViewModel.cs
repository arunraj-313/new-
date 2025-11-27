using PG_Management.Models;
using System.Collections.Generic;

namespace EasyStay.Models
{
    public class AdminDashboardViewModel
    {
        public IEnumerable<PGItem> PGs { get; set; } = new List<PGItem>();
        public List<PGListingModel> RecentPGs { get; set; }
    }

    public class PGItem
    {
        public int Id { get; set; }
        public string Name { get; set; } = "";
        public string Location { get; set; } = "";
        public int RoomCount { get; set; }
        public bool IsActive { get; set; }
    }
}
