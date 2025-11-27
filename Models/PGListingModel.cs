using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.ComponentModel.DataAnnotations;

namespace PG_Management.Models
{
    //public class PGListingModel
    //{
    //    [Key] // Mark as primary key
    //    public int PGID { get; set; }

    //    [Required]
    //    public string PGName { get; set; }

    //    [Required]
    //    public string Location { get; set; }

    //    public string Type { get; set; }
    //    public decimal Rent { get; set; }
    //    public string RoomType { get; set; }
    //    public string ImageURL { get; set; }
    //    public string Description { get; set; }
    //}

    public class PGListingModel
    {
        

        public int PGID { get; set; }

        [Required, StringLength(100)]
        public string PGName { get; set; }

        [Required]
        public string Location { get; set; }
        public string Type { get; set; }

        [Range(1000, 100000)]
        public decimal Rent { get; set; }

        public string RoomType { get; set; }
        public string ImageURL { get; set; }
        public string Description { get; set; }
        public DateTime CreatedDate;
    }

}


