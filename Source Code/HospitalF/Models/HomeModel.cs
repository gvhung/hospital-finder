﻿using System;
using System.Data.Linq;
using System.Linq;
using System.Threading.Tasks;
using System.Web;
using System.Web.Mvc;
using System.ComponentModel.DataAnnotations;
using System.Collections.Generic;
using System.Text.RegularExpressions;
using HospitalF.Constant;
using HospitalF.Models;
using HospitalF.Utilities;
using HospitalF.Entities;

namespace HospitalF.Models
{
    public class HomeModel
    {
        #region Properties

        /// <summary>
        /// Get/Set value for property SearchValue
        /// </summary>
        public string SearchValue { get; set; }

        /// <summary>
        ///  Get/Set value for property HospitalID
        /// </summary>
        public int HospitalID { get; set; }

        /// <summary>
        /// Get/Set value for property CityID
        /// </summary>
        public int CityID { get; set; }

        /// <summary>
        /// Get/Set value for property CityID
        /// </summary>
        public string CityName { get; set; }

        /// <summary>
        /// Get/Set value for property DistrictID
        /// </summary>
        public int DistrictID { get; set; }

        /// <summary>
        /// Get/Set value for property HospitalTypeID
        /// </summary>
        public int HospitalTypeID { get; set; }

        /// <summary>
        /// Get/Set value for property HospitalTypeName
        /// </summary>
        public string HospitalTypeName { get; set; }

        /// <summary>
        /// Get/Set value for property DistrictName
        /// </summary>
        public string DistrictName { get; set; }

        /// <summary>
        /// Get/Set value for property SpecialityID
        /// </summary>
        public int SpecialityID { get; set; }

        /// <summary>
        /// Get/Set value for property SpecialityName
        /// </summary>
        public string SpecialityName { get; set; }

        /// <summary>
        /// Get/Set value for property DiseaseID
        /// </summary>
        public int DiseaseID { get; set; }

        /// <summary>
        /// Get/Set value for property DiseaseName
        /// </summary>
        public string DiseaseName { get; set; }

        /// <summary>
        /// Get/Set value for property AppointedLocation
        /// </summary>
        public string AppointedAddress { get; set; }

        /// <summary>
        /// Get/Set value for property HospitalName
        /// </summary>
        public string HospitalName { get; set; }

        /// <summary>
        /// Get/Set value for property Coordinate
        /// </summary>
        public string Coordinate { get; set; }

        /// <summary>
        /// Get/Set value for property HospitalAddres
        /// </summary>
        public string Position { get; set; }

        /// <summary>
        /// Get/Set value for property Radius
        /// </summary>
        public double Radius { get; set; }

        /// <summary>
        /// Get/Set value for property WhatPhrase
        /// </summary>
        public string WhatPhrase { get; set; }

        /// <summary>
        /// Get/Set value for property WhatPhrase
        /// </summary>
        public int LocationType { get; set; }

        #endregion

        #region GIR Query Analyzer

        /// <summary>
        /// Check if input token is a relation word
        /// </summary>
        /// <param name="inputToken">Input token</param>
        /// <param name="dictionary">Word dictionary</param>
        /// <returns>Boolean indicating if a token is a relation word</returns>
        private bool IsValidRelationWord(string inputStr, List<string> dictionary)
        {
            // Check every word in dictionary to see in the input token is match
            foreach (string word in dictionary)
            {
                // Find matching result
                if (word.ToLower().Equals(inputStr))
                {
                    return true;
                }
            }
            // Return false as default
            return false;
        }

        /// <summary>
        /// Check if input token is a relation word
        /// </summary>
        /// <param name="inputToken">Input token</param>
        /// <param name="cityList">List of cities</param>
        /// <param name="districtList">List of districts</param>
        /// <returns>Boolean indicating if a token is a location phrase</returns>
        private bool IsValidWherePhrase(string inputStr,
            List<City> cityList, List<District> districtList)
        {
            bool isCityFount = false;               // Indicate if city is found
            bool isDistrictFount = false;           // Indicate if district is found

            // Check every word in city list to see if the input token is match
            foreach (City city in cityList)
            {
                // Find matching result for cities
                if (!string.IsNullOrEmpty(city.City_Name) &&
                    StringUtil.IsPatternMatched(StringUtil.RemoveDiacriticMarks(inputStr),
                    StringUtil.RemoveDiacriticMarks(city.City_Name.Trim().ToLower())))
                {
                    this.CityID = city.City_ID;
                    this.CityName = city.City_Name;
                    isCityFount = true;
                    break;
                }
            }

            // Check special district case
            string nonDiacriticeQueryStr = StringUtil.RemoveDiacriticMarks(inputStr);
            if (nonDiacriticeQueryStr.Contains("quan 12"))
            {
                this.DistrictID = 761;
                this.DistrictName = "12";
                isDistrictFount = true;
            }
            if (nonDiacriticeQueryStr.Contains("quan 11"))
            {
                this.DistrictID = 772;
                this.DistrictName = "11";
                isDistrictFount = true;
            }
            if (nonDiacriticeQueryStr.Contains("quan 10"))
            {
                this.DistrictID = 771;
                this.DistrictName = "10";
                isDistrictFount = true;
            }

            if (this.DistrictID == 0)
            {
                // Check every word in district list to see if the input token is match
                foreach (District district in districtList)
                {
                    int tempDistrictIndex = StringUtil.TakeMatchedStringPosition(
                             StringUtil.RemoveDiacriticMarks(inputStr),
                             StringUtil.RemoveDiacriticMarks(district.Type.ToLower()) + Constants.WhiteSpace +
                             StringUtil.RemoveDiacriticMarks(district.District_Name.ToLower()));
                    // Find matching result for districts
                    if (!string.IsNullOrEmpty(district.District_Name) &&
                        StringUtil.IsPatternMatched(StringUtil.RemoveDiacriticMarks(inputStr),
                        StringUtil.RemoveDiacriticMarks(district.District_Name.Trim().ToLower())))
                    {
                        this.DistrictID = district.District_ID;
                        this.DistrictName = district.District_Name;
                        isDistrictFount = true;
                        break;
                    }
                }
            }

            // Check if any city or district is found
            if (isCityFount || isDistrictFount)
            {
                return true;
            }

            // Return false as default
            return false;
        }

        /// <summary>
        /// Take first location in input query string
        /// </summary>
        /// <param name="queryStr">Query string</param>
        /// <param name="cityList">List of cities</param>
        /// <param name="districtList">List of districts</param>
        /// <returns>First location in Where phrase</returns>
        private string TakeFirstLocationInQueryString(string queryStr,
            List<City> cityList, List<District> districtList)
        {
            int cityPosition = 0;                   // City index in Where phrase
            int tempCityIndex = 0;                  // Temp city index
            bool isCityFound = false;               // Indicate if a city is found
            string tempCity = string.Empty;         // Indicate temporary city value
            int districtPosition = 0;               // District index in Where phrase
            int tempDistrictIndex = 0;              // Temp district index
            bool isDistrictFound = false;           // Indicate if a district is found
            string tempDistrict = string.Empty;     // Indicate temporary district value

            // Check every word in city list to see in the input token is match
            foreach (City city in cityList)
            {
                // Find matching result for cities
                if (!string.IsNullOrEmpty(city.City_Name))
                {
                    tempCityIndex = StringUtil.TakeMatchedStringPosition(
                        StringUtil.RemoveDiacriticMarks(queryStr),
                        StringUtil.RemoveDiacriticMarks(city.City_Name.ToLower()));
                    if (tempCityIndex != Constants.DefaultMatchingValue)
                    {
                        cityPosition = tempCityIndex;
                        this.CityID = city.City_ID;
                        this.CityName = city.City_Name;
                        tempCity = city.City_Name;
                        isCityFound = true;
                        break;
                    }
                }
            }

            // Check special district case
            string nonDiacriticeQueryStr = StringUtil.RemoveDiacriticMarks(queryStr);
            if (nonDiacriticeQueryStr.Contains("quan 12"))
            {
                this.DistrictID = 761;
                this.DistrictName = "12";
                isDistrictFound = true;
            }
            if (nonDiacriticeQueryStr.Contains("quan 11"))
            {
                this.DistrictID = 772;
                this.DistrictName = "11";
                isDistrictFound = true;
            }
            if (nonDiacriticeQueryStr.Contains("quan 10"))
            {
                this.DistrictID = 771;
                this.DistrictName = "10";
                isDistrictFound = true;
            }

            if (this.DistrictID == 0)
            {
                // Check every word in district list to see in the input token is match
                foreach (District district in districtList)
                {
                    if (!string.IsNullOrEmpty(district.District_Name))
                    {
                        tempDistrictIndex = StringUtil.TakeMatchedStringPosition(
                             StringUtil.RemoveDiacriticMarks(queryStr),
                             StringUtil.RemoveDiacriticMarks(district.Type.ToLower()) + Constants.WhiteSpace +
                             StringUtil.RemoveDiacriticMarks(district.District_Name.ToLower()));

                        if (tempDistrictIndex != Constants.DefaultMatchingValue)
                        {
                            districtPosition = tempDistrictIndex;
                            this.DistrictID = district.District_ID;
                            this.DistrictName = district.District_Name;
                            tempDistrict = district.Type + Constants.WhiteSpace + district.District_Name;
                            isDistrictFound = true;
                            break;
                        }
                    }
                }
            }

            // Check if there is any city or district are found
            if (isCityFound)
            {
                return tempCity;
            }
            if (isDistrictFound)
            {
                return tempDistrict;
            }

            // Return null as default
            return null;
        }

        /// <summary>
        /// Load all hospitals in database
        /// </summary>
        /// <returns>List[Hospital]</returns>
        private async Task<List<Hospital>> LoadHospitalList()
        {
            // Return list of hospital
            using (LinqDBDataContext data = new LinqDBDataContext())
            {
                return await Task.Run(() =>
                    (from h in data.Hospitals
                     select h).ToList());
            }
        }

        /// <summary>
        /// Handle well-formed What phrase
        /// </summary>
        /// <param name="whatPhrase">Well-formed What phrase</param>
        /// <param name="specialityList">Speciality List</param>
        /// <param name="diseaseList">Disease List</param>
        /// <param name="hospitalList">Hospital List</param>
        private void HandleWellFormedWhatPhrase(string whatPhrase,
            List<Speciality> specialityList, List<Disease> diseaseList,
            List<Hospital> hospitalList)
        {
            // Remove 'bệnh viện' or 'bv' out of what phrase
            whatPhrase = whatPhrase.Replace(Constants.BệnhViện, string.Empty).
                Replace(Constants.Bv, string.Empty).Trim();

            // Check every hospital name in hospital list to see if the input token is match
            foreach (Hospital hospital in hospitalList)
            {
                // Find matching result for hospital
                if (!string.IsNullOrEmpty(hospital.Hospital_Name) &&
                    StringUtil.IsPatternMatched(hospital.Hospital_Name.Trim().ToLower(), whatPhrase))
                {
                    this.HospitalName = whatPhrase;
                    return;
                }
            }

            // Check every speciality name in speciality list to see if the input token is match
            foreach (Speciality speciality in specialityList)
            {
                // Find matching result for speciality
                if (!string.IsNullOrEmpty(speciality.Speciality_Name) &&
                    StringUtil.IsPatternMatched(whatPhrase, speciality.Speciality_Name.Trim().ToLower()))
                {
                    this.SpecialityID = speciality.Speciality_ID;
                    this.SpecialityName = speciality.Speciality_Name;
                    break;
                }
            }

            // Check every disease name in disease list to see if the input token is match
            foreach (Disease disease in diseaseList)
            {
                // Find matching reuslt for disease
                if (!string.IsNullOrEmpty(disease.Disease_Name) &&
                    StringUtil.IsPatternMatched(whatPhrase, disease.Disease_Name.Trim().ToLower()))
                {
                    this.DiseaseID = disease.Disease_ID;
                    this.DiseaseName = disease.Disease_Name;
                    break;
                }
            }
        }

        /// <summary>
        /// Geography Information Retrieval (WHAT - REL - WHERE)
        /// Analyze input query to 3 different phases of What - Relation - Where
        /// </summary>
        /// <param name="inputQuery">inputQuery</param>
        public async Task GIRQueryAnalyzerAsync(string inputQuery)
        {
            string what = string.Empty;             // What phrase
            string tempWhat = string.Empty;         // Temporary value for What phrase
            string relation = string.Empty;         // Relation word
            string tempRelation = string.Empty;     // Temporary value for Relation word 
            string where = string.Empty;            // Where phrase
            string tempWhere = string.Empty;        // Temporary value for Where phrase
            bool isComplete = false;                // Indicate if the process is complete or not

            // Remove redundant white space between words in inputquery
            inputQuery = Regex.Replace(inputQuery, @"\s+", " ");

            // Create a list of tokens
            List<string> tokens = StringUtil.StringTokenizer(inputQuery);
            int sizeOfTokens = tokens.Count();


            // Load relation word dictionary
            List<string> wordDic = await DictionaryUtil.LoadRelationWordAsync();
            // Load list of cities
            List<City> cityList = await LocationUtil.LoadCityAsync();
            // Load list of districts
            List<District> districtList = await LocationUtil.LoadAllDistrictAsync();

            // Check if the lists are load successfully
            if ((wordDic == null) &&
                (cityList == null) &&
                (districtList == null))
            {
                return;
            }

            what = StringUtil.ConcatTokens(tokens, 0, sizeOfTokens - 1);

            // Check every token in the list
            for (int n = 0; n < sizeOfTokens; n++)
            {
                for (int i = n; i < sizeOfTokens; i++)
                {
                    // Concate tokens to create a string with the original starting
                    // word is the first token, and this word is shift to left one index every n loop
                    // if relaton word is not found.
                    // New tokens is add to original token every i loop to check for valid relation word
                    tempRelation = StringUtil.ConcatTokens(tokens, n, i);

                    // Check if token string is matched with relation word in database
                    if (IsValidRelationWord(tempRelation, wordDic))
                    {
                        // If it matches, assign temporary What phrase value with 
                        // the value of leading words before Relation word
                        tempWhat = inputQuery.Substring(0, inputQuery.IndexOf(tempRelation) - 1);

                        // Assign Where phrase value with the value of trailing
                        // words after Relation word
                        where = StringUtil.ConcatTokens(tokens, i + 1, sizeOfTokens - 1).Trim().ToLower();

                        // Check if Where phrase is matched with locaitons in database
                        // and handle Where phrase to locate exactly search locations
                        if (IsValidWherePhrase(where, cityList, districtList))
                        {
                            // Change status of isComplete varialbe
                            isComplete = true;
                            // If matches, assign Relation word is with the value
                            // of temporary relation 
                            relation = tempRelation;
                            // Assign n value again to break the outside loop
                            n = sizeOfTokens;
                            break;
                        }

                        // Assign Relation word with the value of temporary relation
                        // every i loop
                        relation = tempRelation;
                    }
                }
            }

            // Check if the process is completely finished
            if (!isComplete)
            {
                // Handle query in case of input string is not well-formed
                // with Relation word and Where phrase is not found.
                // Auto check Where phrase with the first location value in input query,
                // if Where phrase is valid, auto assign Relation word with default value.
                if (string.IsNullOrEmpty(relation) && string.IsNullOrEmpty(where))
                {
                    int i = 0;

                    // Take first location in input query string
                    // and handle Where phrase (if any) to locate exactly search locations
                    string firstLocation = TakeFirstLocationInQueryString(inputQuery, cityList, districtList);
                    if (!string.IsNullOrEmpty(firstLocation))
                    {
                        i = inputQuery.IndexOf(firstLocation.ToLower());
                        tempWhat = inputQuery.Substring(0, i);
                        if (string.IsNullOrEmpty(tempWhat))
                        {
                            where = firstLocation;
                            if (firstLocation.Length != inputQuery.Length)
                            {
                                tempWhat = inputQuery.Substring(firstLocation.Length).Trim().ToLower();
                            }
                        }
                        else
                        {
                            where = inputQuery.Substring(i).Trim().ToLower();
                        }
                    }
                    else
                    {
                        tempWhat = what;
                        relation = string.Empty;
                        where = string.Empty;
                    }
                }
            }

            // Make sure What phrase have the value.
            // At the worst case if the input query is not well-formed,
            // assign What phrase with the input query
            if (!string.IsNullOrEmpty(tempWhat))
            {
                what = tempWhat.Trim().ToLower();
            }

            // Check if What phrase is equal to Where phrase
            if (what.Equals(where))
            {
                what = string.Empty;
            }

            string a = string.Format("[{0}][{1}][{2}]", what, relation, where);
            int hospitalId = this.HospitalID;
            string hospitalName = this.HospitalName;
            int cityId = this.CityID;
            string cityName = this.CityName;
            int districtId = this.DistrictID;
            string districtName = this.DistrictName;
            int specialityId = this.SpecialityID;
            string speacialityName = this.SpecialityName;
            int diseaseId = this.DiseaseID;
            string diseaseName = this.DiseaseName;
            this.WhatPhrase = what;
        }

        #endregion

        #region Search Hospital

        /// <summary>
        /// Search hospitals in database using normal option
        /// </summary>
        /// <returns></returns>
        public async Task<List<HospitalEntity>> NormalSearchHospital()
        {
            List<HospitalEntity> hospitalList = null;

            // Take input values
            int cityId = this.CityID;
            int districtId = this.DistrictID;
            string whatPhrase = this.WhatPhrase;

            // Search for suitable hospitals in database
            using (LinqDBDataContext data = new LinqDBDataContext())
            {
                hospitalList = await Task.Run(() =>
                    (from h in data.SP_NORMAL_SEARCH_HOSPITAL(whatPhrase.Trim().ToLower(),
                         cityId, districtId)
                     select new HospitalEntity()
                     {
                         Hospital_ID = h.Hospital_ID,
                         Hospital_Name = h.Hospital_Name,
                         Address = h.Address,
                         Ward_ID = h.Ward_ID,
                         District_ID = h.District_ID,
                         City_ID = h.City_ID,
                         Phone_Number = h.Phone_Number,
                         Coordinate = h.Coordinate,
                         Is_Active = h.Is_Active,
                         Rating = h.Rating
                     }).ToList());
            }

            // Return list of hospitals
            return hospitalList;
        }

        /// <summary>
        ///  Search hospitals in database using Advanced option
        /// </summary>
        /// <param name="cityId">City ID</param>
        /// <param name="districtId">District ID</param>
        /// <param name="specialityId">Speciality ID</param>
        /// <param name="diseaseName">Disease name</param>
        /// <returns>List[HospitalEntity] that contains a list of Hospitals</returns>
        public async Task<List<HospitalEntity>> AdvancedSearchHospital(int cityId,
            int districtId, int specialityId, string diseaseName)
        {
            List<HospitalEntity> hospitalList = null;

            // Search for suitable hospitals in database
            using (LinqDBDataContext data = new LinqDBDataContext())
            {
                hospitalList = await Task.Run(() =>
                    (from h in data.SP_ADVANCED_SEARCH_HOSPITAL(cityId, districtId, specialityId, diseaseName)
                     select new HospitalEntity()
                     {
                         Hospital_ID = h.Hospital_ID,
                         Hospital_Name = h.Hospital_Name,
                         Address = h.Address,
                         Ward_ID = h.Ward_ID,
                         District_ID = h.District_ID,
                         City_ID = h.City_ID,
                         Phone_Number = h.Phone_Number,
                         Coordinate = h.Coordinate,
                         Is_Active = h.Is_Active,
                         Rating = h.Rating
                     }).ToList());
            }

            // Return list of hospitals
            return hospitalList;
        }

        /// <summary>
        /// Search hospitals in database using Location option
        /// </summary>
        /// <param name="latitude">Latitide</param>
        /// <param name="longitude">Longitude</param>
        /// <param name="distance">Distance between 2 locations</param>
        /// <returns>List[HospitalEntity] that contains a list of Hospitals</returns>
        public static async Task<List<HospitalEntity>> LocationSearchHospital(double latitude, double longitude, double distance)
        {
            List<HospitalEntity> hospitalList = null;

            // Search for suitable hospitals in database
            using (LinqDBDataContext data = new LinqDBDataContext())
            {
                hospitalList = await Task.Run(() =>
                    (from h in data.SP_LOCATION_SEARCH_HOSPITAL(latitude, longitude, distance)
                     select new HospitalEntity()
                     {
                         Hospital_ID = h.Hospital_ID,
                         Hospital_Name = h.Hospital_Name,
                         Address = h.Address,
                         Ward_ID = h.Ward_ID,
                         District_ID = h.District_ID,
                         City_ID = h.City_ID,
                         Phone_Number = h.Phone_Number,
                         Coordinate = h.Coordinate,
                         Is_Active = h.Is_Active,
                         Rating = h.Rating
                     }).ToList());
            }

            // Return list of hospitals
            return hospitalList;
        }

        #endregion

        #region Other Functions
        public static async Task<HospitalEntity> LoadHospitalById(int id)
        {
            HospitalEntity hospital = null;
            using (LinqDBDataContext data = new LinqDBDataContext())
            {
                hospital = await Task.Run(() => (from h in data.Hospitals
                                                 from ht in data.HospitalTypes
                                                 where h.Hospital_ID == id && h.Hospital_Type == ht.Type_ID && h.Is_Active == true
                                                 select new HospitalEntity()
                                                 {
                                                     Hospital_ID = h.Hospital_ID,
                                                     Hospital_Name = h.Hospital_Name,
                                                     Hospital_Type = h.Hospital_Type,
                                                     Hospital_Type_Name = ht.Type_Name,
                                                     Address = h.Address,
                                                     Ward_ID = h.Ward_ID,
                                                     District_ID = h.District_ID,
                                                     City_ID = h.City_ID,
                                                     Phone_Number = h.Phone_Number,
                                                     Fax = h.Fax,
                                                     Email = h.Email,
                                                     Website = h.Website,
                                                     Ordinary_Start_Time = h.Ordinary_Start_Time,
                                                     Ordinary_End_Time = h.Ordinary_End_Time,
                                                     Holiday_Start_Time = h.Holiday_Start_Time,
                                                     Holiday_End_Time = h.Holiday_End_Time,
                                                     Coordinate = h.Coordinate,
                                                     Description = h.Full_Description,
                                                     Rating = h.Rating,
                                                     Rating_Count = h.Rating_Count,
                                                     Is_Allow_Appointment = h.Is_Allow_Appointment,
                                                     Is_Active = h.Is_Active
                                                 }).SingleOrDefault());
            }
            return hospital;
        }

        public static bool RateHospital(int userId, int hospitalId, int score)
        {
            using (LinqDBDataContext data = new LinqDBDataContext())
            {
                int result = data.SP_RATE_HOSPITAL(userId, hospitalId, score);
                return (result > 0);
            }
        }

        public static List<ServiceEntity> LoadServicesByHospitalId(int id)
        {
            List<ServiceEntity> services = null;
            using (LinqDBDataContext data = new LinqDBDataContext())
            {
                services = (from s in data.SP_LOAD_SERVICES_BY_HOSPITAL_ID(id)
                            select new ServiceEntity()
                            {
                                Service_ID = s.Service_ID,
                                Service_Name = s.Service_Name,
                                Type_ID = s.Type_ID,
                                Type_Name = s.Type_Name,
                                Is_Active = s.Is_Active
                            }).ToList<ServiceEntity>();
            }
            return services;

        }

        public static List<FacilityEntity> LoadFacillitiesByHospitalId(int id)
        {
            List<FacilityEntity> facilities = null;
            using (LinqDBDataContext data = new LinqDBDataContext())
            {
                facilities = (from f in data.SP_LOAD_FACILITIES_BY_HOSPITAL_ID(id)
                              select new FacilityEntity()
                              {
                                  Facility_ID = f.Facility_ID,
                                  Facility_Name = f.Facility_Name,
                                  Type_ID = f.Type_ID,
                                  Type_Name = f.Type_Name,
                                  Is_Active = f.Is_Active
                              }).ToList<FacilityEntity>();
            }
            return facilities;

        }

        public static List<Speciality> LoadSpecialitiesByHospitalId(int id)
        {
            List<Speciality> sepcilities = null;
            using (LinqDBDataContext data = new LinqDBDataContext())
            {
                sepcilities = (from s in data.SP_LOAD_SPECIALITY_BY_HOSPITALID(id)
                               select new Speciality()
                               {
                                   Speciality_ID = s.Speciality_ID,
                                   Speciality_Name = s.Speciality_Name
                               }).ToList<Speciality>();
            }
            return sepcilities;
        }

        public static List<Photo> LoadPhotosByHospitalId(int id)
        {
            List<Photo> photos = null;
            using (LinqDBDataContext data = new LinqDBDataContext())
            {
                photos = (from p in data.Photos
                          where p.Hospital_ID == id && p.Is_Active == true
                          select p).ToList<Photo>();
            }
            return photos;
        }

        #endregion
    }
}