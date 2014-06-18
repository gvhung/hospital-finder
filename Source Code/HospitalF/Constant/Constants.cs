﻿using System.Collections.Generic;
namespace HospitalF.Constant
{
    /// <summary>
    /// Class define constant values for project
    /// </summary>
    public class Constants
    {
        #region Controller and View name

        /// <summary>
        /// Name of _HomeLayout
        /// </summary>
        public const string HomeLayout = "_HomeLayout";

        /// <summary>
        /// Name of _AdminLayout
        /// </summary>
        public const string AdmidLayout = "_AdminLayout";

        /// <summary>
        /// Name of _HospitalUserLayout
        /// </summary>
        public const string HospitalUserLayout = "_HospitalUserLayout";

        /// <summary>
        /// Name of Error page
        /// </summary>
        public const string ErrorPage = "Error";

        /// <summary>
        /// Name of HomeController
        /// </summary>
        public const string HomeController = "Home";

        /// <summary>
        /// Name of Index method
        /// </summary>
        public const string IndexMethod = "Index";

        /// <summary>
        /// Name of SearchResult methodd
        /// </summary>
        public const string SearchResultMethod = "SearchResult";

        #endregion

        #region HomeModel

        /// <summary>
        /// Vietnamese name of property SearchValue
        /// </summary>
        public const string SearchValue = "Giá trị tìm kiếm";

        /// <summary>
        /// Vietnamese name of property Speciality
        /// </summary>
        public const string Speciality = "Chuyên khoa";

        /// <summary>
        /// Vietnamese name of property InputDisease
        /// </summary>
        public const string Disease = "Triệu chứng";

        /// <summary>
        /// Vietnamese name of property Province
        /// </summary>
        public const string City = "Tỉnh thành";

        /// <summary>
        /// Vietnamese name of property District
        /// </summary>
        public const string District = "Quận / Huyện";

        /// <summary>
        ///  Vietnamese name of property CurrentLocation
        /// </summary>
        public const string CurrentLocation = "Địa điểm hiện tại";

        /// <summary>
        ///  Vietnamese name of property AppointedAddress
        /// </summary>
        public const string AppointedAddress = "Địa điểm chỉ định";

        /// <summary>
        /// Vietnamese name of property HospitalName
        /// </summary>
        public const string HospitalName = "Tên bệnh viện";

        /// <summary>
        /// Vietnamese name of property HospitalAddress
        /// </summary>
        public const string HospitalAddress = "Địa chỉ bệnh viện";

        /// <summary>
        /// Vietnamese name of property Coordinate
        /// </summary>
        public const string Coordinate = "Tọa độ";

        /// <summary>
        /// Default matching value
        /// </summary>
        public const int DefaultMatchingValue = 9999;

        #endregion

        #region Regular express

        /// <summary>
        /// Regular expression to find white spaces
        /// </summary>
        public const string FindWhiteSpaceRegex = @"\w+";

        #endregion

        #region Constant value in database



        #endregion

        #region Characters

        /// <summary>
        /// Constant for character " "
        /// </summary>
        public const string WhiteSpace = " ";

        #endregion
    }
}