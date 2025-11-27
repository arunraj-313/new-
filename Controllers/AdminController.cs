using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data.SqlClient;
using System.Web.Mvc;
using EasyStay.Models;
using PG_Management.Models;

namespace PG.Controllers   // or your global namespace "StayEasy"
{
    public class AdminController : Controller
    {
        private readonly string connString = ConfigurationManager.ConnectionStrings["EasyPG"].ConnectionString;

        // ===================== DASHBOARD ======================
        public ActionResult AdminDashboard()

        {

            if (Session["Role"] == null || Session["Role"].ToString() != "Admin")

                return RedirectToAction("Login", "Account");



            int adminId = Convert.ToInt32(Session["UserID"]);



            var model = new AdminDashboardViewModel();

            model.RecentPGs = new List<PGListingModel>();



            using (SqlConnection con = new SqlConnection(connString))

            {

                con.Open();



                // Count PGs

                SqlCommand cmd1 = new SqlCommand("SELECT COUNT(*) FROM PGListings WHERE AdminID=@A", con);

                cmd1.Parameters.AddWithValue("@A", adminId);

                ViewBag.TotalPGs = (int)cmd1.ExecuteScalar();



                // Count Users

                SqlCommand cmd2 = new SqlCommand(

         "SELECT COUNT(*) FROM Users WHERE PGID IN (SELECT PGID FROM PGListings WHERE AdminID=@A)", con);

                cmd2.Parameters.AddWithValue("@A", adminId);

                ViewBag.TotalUsers = (int)cmd2.ExecuteScalar();



                // Count Admins

                SqlCommand cmd3 = new SqlCommand("SELECT COUNT(*) FROM Admins", con);

                ViewBag.TotalAdmins = (int)cmd3.ExecuteScalar();



                // Load recent PGs

                SqlCommand cmd4 = new SqlCommand(

         "SELECT TOP 5 PGID, PGName, Location, Type, Rent FROM PGListings WHERE AdminID=@A ORDER BY PGID DESC", con);

                cmd4.Parameters.AddWithValue("@A", adminId);



                SqlDataReader dr = cmd4.ExecuteReader();

                while (dr.Read())

                {

                    model.RecentPGs.Add(new PGListingModel

                    {

                        PGID = (int)dr["PGID"],

                        PGName = dr["PGName"].ToString(),

                        Location = dr["Location"].ToString(),

                        Type = dr["Type"].ToString(),

                        Rent = Convert.ToDecimal(dr["Rent"])

                    });

                }

            }



            return View(model);

        }

        // ===================== MANAGE USERS ======================
        public ActionResult ManageUsers()
        {
            if (Session["Role"] == null || Session["Role"].ToString() != "Admin")
            {
                TempData["error"] = "Access Denied!";
                return RedirectToAction("Login", "Account");
            }

            int adminId = Convert.ToInt32(Session["UserID"]);
            List<UserModel> users = new List<UserModel>();

            try
            {
                using (SqlConnection con = new SqlConnection(connString))
                {
                    string query = @"
                    SELECT u.UserID, u.FullName, u.Email, u.Gender, u.PhoneNo, p.PGName
                    FROM Users u
                    INNER JOIN PGListings p ON u.PGID = p.PGID
                    WHERE p.AdminID = @AdminID";

                    SqlCommand cmd = new SqlCommand(query, con);
                    cmd.Parameters.AddWithValue("@AdminID", adminId);
                    con.Open();

                    SqlDataReader dr = cmd.ExecuteReader();
                    while (dr.Read())
                    {
                        users.Add(new UserModel
                        {
                            UserID = Convert.ToInt32(dr["UserID"]),
                            FullName = dr["FullName"].ToString(),
                            Email = dr["Email"].ToString(),
                            Gender = dr["Gender"].ToString(),
                            PhoneNo = dr["PhoneNo"].ToString(),
                            Address = dr["PGName"].ToString()  // showing PG name
                        });
                    }
                }
            }
            catch (Exception ex)
            {
                TempData["error"] = "Error loading users: " + ex.Message;
            }

            return View(users);
        }


        // ===================== USERS DETAILS PAGE ======================
        public ActionResult UsersDetails()
        {
            if (Session["Role"] == null || Session["Role"].ToString() != "Admin")
            {
                TempData["error"] = "Access Denied!";
                return RedirectToAction("Login", "Account");
            }

            int adminId = Convert.ToInt32(Session["UserID"]);
            List<UserModel> users = new List<UserModel>();

            using (SqlConnection con = new SqlConnection(connString))
            {
                string query = @"
                SELECT u.UserID, u.FullName, u.Email, u.PhoneNo, u.Gender,
                       p.PGName, p.Location, p.Rent
                FROM Users u
                INNER JOIN PGListings p ON u.PGID = p.PGID
                WHERE p.AdminID = @AdminID";

                SqlCommand cmd = new SqlCommand(query, con);
                cmd.Parameters.AddWithValue("@AdminID", adminId);
                con.Open();

                SqlDataReader dr = cmd.ExecuteReader();
                while (dr.Read())
                {
                    users.Add(new UserModel
                    {
                        UserID = Convert.ToInt32(dr["UserID"]),
                        FullName = dr["FullName"].ToString(),
                        Email = dr["Email"].ToString(),
                        PhoneNo = dr["PhoneNo"].ToString(),
                        Gender = dr["Gender"].ToString(),
                        Address = $"{dr["PGName"]} - {dr["Location"]}",
                        Occupation = "Rent: ₹" + dr["Rent"].ToString()
                    });
                }
            }

            return View(users);
        }

        // ===================== EDIT USER ======================
        [HttpGet]
        public ActionResult EditUser(int id)
        {
            if (Session["Role"] == null || Session["Role"].ToString() != "Admin")
            {
                TempData["error"] = "Access Denied!";
                return RedirectToAction("Login", "Account");
            }

            UserModel user = null;

            using (SqlConnection con = new SqlConnection(connString))
            {
                string query = "SELECT UserID, FullName, Email, PhoneNo, Gender FROM Users WHERE UserID=@UserID";
                SqlCommand cmd = new SqlCommand(query, con);
                cmd.Parameters.AddWithValue("@UserID", id);
                con.Open();

                SqlDataReader dr = cmd.ExecuteReader();
                if (dr.Read())
                {
                    user = new UserModel
                    {
                        UserID = Convert.ToInt32(dr["UserID"]),
                        FullName = dr["FullName"].ToString(),
                        Email = dr["Email"].ToString(),
                        PhoneNo = dr["PhoneNo"].ToString(),
                        Gender = dr["Gender"].ToString()
                    };
                }
            }

            return View(user);
        }

        // POST Update User
        [HttpPost]
        public ActionResult EditUser(UserModel model)
        {
            using (SqlConnection con = new SqlConnection(connString))
            {
                string query = @"UPDATE Users SET FullName=@FullName, Email=@Email,
                                 PhoneNo=@PhoneNo, Gender=@Gender WHERE UserID=@UserID";

                SqlCommand cmd = new SqlCommand(query, con);
                cmd.Parameters.AddWithValue("@FullName", model.FullName);
                cmd.Parameters.AddWithValue("@Email", model.Email);
                cmd.Parameters.AddWithValue("@PhoneNo", model.PhoneNo);
                cmd.Parameters.AddWithValue("@Gender", model.Gender);
                cmd.Parameters.AddWithValue("@UserID", model.UserID);

                con.Open();
                cmd.ExecuteNonQuery();
            }

            TempData["success"] = "User updated successfully!";
            return RedirectToAction("UsersDetails");
        }


        // ===================== DELETE USER ======================
        public ActionResult DeleteUser(int id)
        {
            if (Session["Role"] == null || Session["Role"].ToString() != "Admin")
            {
                TempData["error"] = "Access Denied!";
                return RedirectToAction("Login", "Account");
            }

            try
            {
                using (SqlConnection con = new SqlConnection(connString))
                {
                    SqlCommand cmd = new SqlCommand("DELETE FROM Users WHERE UserID=@UserID", con);
                    cmd.Parameters.AddWithValue("@UserID", id);
                    con.Open();
                    cmd.ExecuteNonQuery();
                }

                TempData["success"] = "User deleted successfully!";
            }
            catch (Exception ex)
            {
                TempData["error"] = "Error deleting user: " + ex.Message;
            }

            return RedirectToAction("ManageUsers");
        }
    }
}