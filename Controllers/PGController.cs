using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data.SqlClient;
using System.IO;
using System.Web;
using System.Web.Mvc;
using PG_Management.Models;

namespace PG_Management.Controllers
{
    public class PGController : Controller
    {
        string connString = ConfigurationManager.ConnectionStrings["EasyPG"].ConnectionString;

        // ===================== ADD PG ======================
        [HttpGet]
        public ActionResult AddPG()
        {
            if (Session["Role"] == null || Session["Role"].ToString() != "Admin")
            {
                TempData["error"] = "Access Denied!";
                return RedirectToAction("Login", "Account");
            }
            return View();
        }

        [HttpPost]
        public ActionResult AddPG(PGListingModel pg, HttpPostedFileBase ImageFile)
        {
            if (!ModelState.IsValid)
            {
                TempData["error"] = "Please fill all fields correctly!";
                return View(pg);
            }

            try
            {
                // Handle Image Upload
                if (ImageFile != null && ImageFile.ContentLength > 0)
                {
                    string fileName = Path.GetFileName(ImageFile.FileName);
                    string path = Path.Combine(Server.MapPath("~/Content/Images"), fileName);
                    ImageFile.SaveAs(path);
                    pg.ImageURL = "/Content/Images/" + fileName;
                }

                using (SqlConnection con = new SqlConnection(connString))
                {
                    string query = @"INSERT INTO PGListings
                                    (PGName, Location, Type, Rent, RoomType, ImageURL, Description)
                                    VALUES (@PGName, @Location, @Type, @Rent, @RoomType, @ImageURL, @Description)";
                    SqlCommand cmd = new SqlCommand(query, con);
                    cmd.Parameters.AddWithValue("@PGName", pg.PGName);
                    cmd.Parameters.AddWithValue("@Location", pg.Location);
                    cmd.Parameters.AddWithValue("@Type", pg.Type);
                    cmd.Parameters.AddWithValue("@Rent", pg.Rent);
                    cmd.Parameters.AddWithValue("@RoomType", pg.RoomType);
                    cmd.Parameters.AddWithValue("@ImageURL", pg.ImageURL ?? "");
                    cmd.Parameters.AddWithValue("@Description", pg.Description);
                    con.Open();
                    cmd.ExecuteNonQuery();
                }

                TempData["success"] = "PG Listing Added Successfully!";
                return RedirectToAction("ViewPG");
            }
            catch (Exception ex)
            {
                TempData["error"] = "Error adding PG: " + ex.Message;
                return View(pg);
            }
        }

        // ===================== VIEW PG ======================
        public ActionResult ViewPG(string query)
        {
            if (Session["Role"] == null || Session["Role"].ToString() != "Admin")
            {
                TempData["error"] = "Access Denied!";
                return RedirectToAction("Login", "Account");
            }

            List<PGListingModel> pgList = new List<PGListingModel>();
            using (SqlConnection con = new SqlConnection(connString))
            {
                string sql = "SELECT * FROM PGListings";
                if (!string.IsNullOrEmpty(query))
                {
                    sql += " WHERE PGName LIKE @Query OR Location LIKE @Query";
                }

                SqlCommand cmd = new SqlCommand(sql, con);
                if (!string.IsNullOrEmpty(query))
                {
                    cmd.Parameters.AddWithValue("@Query", "%" + query + "%");
                }

                con.Open();
                SqlDataReader dr = cmd.ExecuteReader();
                while (dr.Read())
                {
                    pgList.Add(new PGListingModel
                    {
                        PGID = Convert.ToInt32(dr["PGID"]),
                        PGName = dr["PGName"].ToString(),
                        Location = dr["Location"].ToString(),
                        Type = dr["Type"].ToString(),
                        Rent = Convert.ToDecimal(dr["Rent"]),
                        RoomType = dr["RoomType"].ToString(),
                        ImageURL = dr["ImageURL"].ToString(),
                        Description = dr["Description"].ToString()
                    });
                }
            }
            return View(pgList);
        }

        // ===================== EDIT PG ======================
        [HttpGet]
        public ActionResult EditPG(int id)
        {
            PGListingModel pg = null;
            using (SqlConnection con = new SqlConnection(connString))
            {
                string query = "SELECT * FROM PGListings WHERE PGID=@PGID";
                SqlCommand cmd = new SqlCommand(query, con);
                cmd.Parameters.AddWithValue("@PGID", id);
                con.Open();
                SqlDataReader dr = cmd.ExecuteReader();
                if (dr.Read())
                {
                    pg = new PGListingModel
                    {
                        PGID = Convert.ToInt32(dr["PGID"]),
                        PGName = dr["PGName"].ToString(),
                        Location = dr["Location"].ToString(),
                        Type = dr["Type"].ToString(),
                        Rent = Convert.ToDecimal(dr["Rent"]),
                        RoomType = dr["RoomType"].ToString(),
                        ImageURL = dr["ImageURL"].ToString(),
                        Description = dr["Description"].ToString()
                    };
                }
            }
            return View(pg);
        }

        [HttpPost]
        public ActionResult EditPG(PGListingModel pg, HttpPostedFileBase ImageFile)
        {
            try
            {
                if (ImageFile != null && ImageFile.ContentLength > 0)
                {
                    string fileName = Path.GetFileName(ImageFile.FileName);
                    string path = Path.Combine(Server.MapPath("~/Content/Images"), fileName);
                    ImageFile.SaveAs(path);
                    pg.ImageURL = "/Content/Images/" + fileName;
                }

                using (SqlConnection con = new SqlConnection(connString))
                {
                    string query = @"UPDATE PGListings SET PGName=@PGName, Location=@Location, Type=@Type, Rent=@Rent,
                                     RoomType=@RoomType, ImageURL=@ImageURL, Description=@Description WHERE PGID=@PGID";
                    SqlCommand cmd = new SqlCommand(query, con);
                    cmd.Parameters.AddWithValue("@PGName", pg.PGName);
                    cmd.Parameters.AddWithValue("@Location", pg.Location);
                    cmd.Parameters.AddWithValue("@Type", pg.Type);
                    cmd.Parameters.AddWithValue("@Rent", pg.Rent);
                    cmd.Parameters.AddWithValue("@RoomType", pg.RoomType);
                    cmd.Parameters.AddWithValue("@ImageURL", pg.ImageURL ?? "");
                    cmd.Parameters.AddWithValue("@Description", pg.Description);
                    cmd.Parameters.AddWithValue("@PGID", pg.PGID);
                    con.Open();
                    cmd.ExecuteNonQuery();
                }

                TempData["success"] = "PG Listing Updated Successfully!";
                return RedirectToAction("ViewPG");
            }
            catch (Exception ex)
            {
                TempData["error"] = "Error updating PG: " + ex.Message;
                return View(pg);
            }
        }

        // ===================== DELETE PG ======================
        public ActionResult DeletePG(int id)
        {
            try
            {
                using (SqlConnection con = new SqlConnection(connString))
                {
                    string query = "DELETE FROM PGListings WHERE PGID=@PGID";
                    SqlCommand cmd = new SqlCommand(query, con);
                    cmd.Parameters.AddWithValue("@PGID", id);
                    con.Open();
                    cmd.ExecuteNonQuery();
                }
                TempData["success"] = "PG Listing Deleted Successfully!";
            }
            catch (Exception ex)
            {
                TempData["error"] = "Error deleting PG: " + ex.Message;
            }
            return RedirectToAction("ViewPG");
        }
    }
}