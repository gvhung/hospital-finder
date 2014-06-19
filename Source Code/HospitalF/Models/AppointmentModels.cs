﻿using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Web;
using System.Threading.Tasks;
using HospitalF.Constant;
using HospitalF.Entities;

namespace HospitalF.Models
{
    public class AppointmentModels
    {
        #region Properties

        /// <summary>
        /// Get/set value for property FullName
        /// </summary>
        [Display(Name = Constants.FullName)]
        [Required(ErrorMessage = ErrorMessage.CEM001)]
        [StringLength(32, ErrorMessage = ErrorMessage.CEM003)]
        public string FullName { get; set; }
        
        /// <summary>
        /// Get/set value for property Gender
        /// </summary>
        [Display(Name = Constants.Gender)]
        public int Gender { get; set; }

        /// <summary>
        /// Get/set value for property Birthday
        /// </summary>
        [Display(Name = Constants.Birthday)]
        public DateTime Birthday { get; set; }

        /// <summary>
        /// Get/set value for property Email
        /// </summary>
        [Display(Name = Constants.Email)]
        [RegularExpression(Constants.EmailRegex, ErrorMessage = ErrorMessage.CEM005)]
        public string Email { get; set; }

        /// <summary>
        /// Get/set value for property PhoneNo
        /// </summary>
        [Display(Name=Constants.PhoneNo)]
        [Required(ErrorMessage=ErrorMessage.CEM001)]
        [RegularExpression(Constants.CellPhoneNoRegex,ErrorMessage=ErrorMessage.CEM005)]
        public string PhoneNo { get; set; }
        
        /// <summary>
        /// Get/set value for property Speciality_ID
        /// </summary>
        [Display(Name=Constants.Speciality)]
        public int Speciality_ID { get; set; }

        /// <summary>
        /// Get/Set value for property Speciality_Name
        /// </summary>
        public string Speciality_Name { get; set; }

        /// <summary>
        /// Get/set value for property Doctor_ID
        /// </summary>
        [Display(Name=Constants.Doctor)]
        public int Doctor_ID { get; set; }

        /// <summary>
        /// Get/set value for property Doctor_Name
        /// </summary>
        public string Doctor_Name { get; set; }
        /// <summary>
        /// Get/set value for property App_Date
        /// </summary>
        [Display(Name=Constants.App_Date)]
        public DateTime App_Date { get; set; }

        /// <summary>
        /// Get/set value for property StartTime
        /// </summary>
        [Display(Name=Constants.StartTime)]
        public string StartTime { get; set; }

        #endregion

        #region Load doctor
        /// <summary>
        /// Load all doctor in Doctor_Speciality
        /// </summary>
        /// <param name="SpecialityID"></param>
        /// <returns>List[DoctorEnity] that contains list of doctor with appropriate Speciality code</returns>
        public static async Task<List<DoctorEntity>> LoadDoctorInDoctorSpecialityAsyn(int SpecialityID)
        {
            List<DoctorEntity> doctorList = new List<DoctorEntity>();
            DoctorEntity doctor = null;
            List<SP_LOAD_DOCTOR_IN_DOCTOR_SPECIALITYResult> result = null;
            // Take doctor in specific speciality in database
            using (LinqDBDataContext data = new LinqDBDataContext())
            {
                result = await Task.Run(() =>
                data.SP_LOAD_DOCTOR_IN_DOCTOR_SPECIALITY(SpecialityID).ToList());
            }
            // Assign value for each doctor
            foreach (SP_LOAD_DOCTOR_IN_DOCTOR_SPECIALITYResult r in result)
            {
                doctor = new DoctorEntity();
                doctor.DoctorID = r.Doctor_ID;
                doctor.FirstName = r.First_Name;
                doctor.LastName = r.Last_Name;
                doctorList.Add(doctor);
            }
            return doctorList;
        }
        #endregion
    }
}