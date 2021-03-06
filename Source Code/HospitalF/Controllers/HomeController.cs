﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System.Web;
using System.Web.Mvc;
using HospitalF.Constant;
using HospitalF.Models;
using HospitalF.Entities;
using HospitalF.App_Start;
using HospitalF.Utilities;
using Newtonsoft.Json;
using System.Net;
using Newtonsoft.Json.Linq;
using PagedList;
using System.Collections.Specialized;
using Recaptcha.Web;
using Recaptcha.Web.Mvc;

namespace HospitalF.Controllers
{
    public class HomeController : SecurityBaseController
    {
        // Declare public list items for Drop down lists
        public static List<City> cityList = null;
        public static List<District> districtList = null;
        public static List<Speciality> specialityList = null;
        public static List<Disease> diseaseList = null;

        #region AJAX calling methods

        /// <summary>
        /// GET: /Home/GetDistrictByCity
        /// </summary>
        /// <param name="cityId">City ID</param>
        /// <returns>Task[ActionResult] with JSON contains list of Districts</returns>
        public async Task<ActionResult> GetDistrictByCity(string cityId)
        {
            try
            {
                int tempCityId = 0;
                // Check if city ID is null or not
                if (!String.IsNullOrEmpty(cityId) && Int32.TryParse(cityId, out tempCityId))
                {
                    districtList = await LocationUtil.LoadDistrictInCityAsync(tempCityId);
                    var result = (from d in districtList
                                  select new
                                  {
                                      id = d.District_ID,
                                      name = d.Type + Constants.WhiteSpace + d.District_Name
                                  });
                    return Json(result, JsonRequestBehavior.AllowGet);
                }
                else
                {
                    // Return default value
                    districtList = new List<District>();
                    return Json(districtList, JsonRequestBehavior.AllowGet);
                }
            }
            catch (Exception exception)
            {
                LoggingUtil.LogException(exception);
                return RedirectToAction(Constants.SystemFailureHomeAction, Constants.ErrorController);
            }
        }

        /// <summary>
        /// GET: /Home/GetDeseaseBySpeciality
        /// </summary>
        /// <param name="specialityId">SpecialityId ID</param>
        /// <returns>Task[ActionResult] with JSON contains list of Deseases</returns>
        public async Task<ActionResult> GetDeseaseBySpeciality(string specialityId)
        {
            try
            {
                int tempSpecialityId = 0;
                // Check if city ID is null or not
                if (!String.IsNullOrEmpty(specialityId) && Int32.TryParse(specialityId, out tempSpecialityId))
                {
                    diseaseList = await SpecialityUtil.LoadDiseaseInSpecialityAsync(tempSpecialityId);
                    var result = (from d in diseaseList
                                  select new
                                  {
                                      name = d.Disease_Name
                                  });
                    return Json(result, JsonRequestBehavior.AllowGet);
                }
                else
                {
                    // Return default value
                    diseaseList = new List<Disease>();
                    return Json(districtList, JsonRequestBehavior.AllowGet);
                }
            }
            catch (Exception exception)
            {
                LoggingUtil.LogException(exception);
                return RedirectToAction(Constants.SystemFailureHomeAction, Constants.ErrorController);
            }
        }

        /// <summary>
        /// GET: /Home/GetDeseaseBySpeciality
        /// </summary>
        /// <returns>ask[ActionResult] with JSON contains list of Setences</returns>
        public async Task<ActionResult> LoadSuggestSentence(string searchQuery)
        {
            try
            {
                // Return list of sentences
                List<string> sentenceDic = await DictionaryUtil.LoadSuggestSentenceAsync(searchQuery.Trim());
                return Json(sentenceDic, JsonRequestBehavior.AllowGet);
            }
            catch (Exception exception)
            {
                LoggingUtil.LogException(exception);
                return RedirectToAction(Constants.SystemFailureHomeAction, Constants.ErrorController);
            }
        }

        #endregion

        #region Search hospital

        /// <summary>
        /// GET: /Home/Index
        /// </summary>
        /// <returns>Task[ActionResult]</returns>
        [LayoutInjecter(Constants.HomeLayout)]
        public async Task<ActionResult> Index()
        {
            try
            {
                // Load list of cities
                cityList = await LocationUtil.LoadCityAsync();
                ViewBag.CityList = new SelectList(cityList, Constants.CityID, Constants.CityName);
                // Load list of districts
                districtList = new List<District>();
                ViewBag.DistrictList = new SelectList(districtList, Constants.DistrictID, Constants.DistrictName);
                // Load list of specialities
                specialityList = await SpecialityUtil.LoadSpecialityAsync();
                ViewBag.SpecialityList = new SelectList(specialityList, Constants.SpecialityID, Constants.SpecialityName);
                // Load list of disease
                diseaseList = new List<Disease>();
                ViewBag.DiseaseList = new SelectList(diseaseList, Constants.DiseaseID, Constants.DiseaseName);

                List<SelectListItem> locationTypeListItem = new List<SelectListItem>()
                                                                {
                                                                    new SelectListItem {Value = "2", Text = "Nhập vị trí"},
                                                                    new SelectListItem {Value = "1", Text = "Vị trí hiện tại", }
                                                                };
                ViewBag.LocationTypeList = new SelectList(locationTypeListItem, "Value", "Text", 2);
                List<SelectListItem> radiusListItem = new List<SelectListItem>()
                                                                {
                                                                    new SelectListItem {Value = "0.3", Text = "300 mét"},
                                                                    new SelectListItem {Value = "0.5", Text = "500 mét"},
                                                                    new SelectListItem {Value = "1", Text = "1 km"},
                                                                    new SelectListItem {Value = "3", Text = "3 km"},
                                                                    new SelectListItem {Value = "5", Text = "5 km"},
                                                                    new SelectListItem {Value = "10", Text = "10 km"},
                                                                    new SelectListItem {Value = "15", Text = "15 km"},
                                                                    new SelectListItem {Value = "20", Text = "20 km"}
                                                                };
                ViewBag.RadiusList = new SelectList(radiusListItem, "Value", "Text", 0.3);

                ViewBag.FeedbackStatus = TempData["FeedbackStatus"];
                ViewBag.FeedbackMessage = TempData["FeedbackMessage"];
            }
            catch (Exception exception)
            {
                LoggingUtil.LogException(exception);
                return RedirectToAction(Constants.SystemFailureHomeAction, Constants.ErrorController);
            }

            return View();
        }

        /// <summary>
        /// GET: /Home/Index
        /// </summary>
        /// <param name="model">HomeModel</param>
        /// <returns>Task[ActionResult]</returns>
        [HttpGet]
        [LayoutInjecter(Constants.HomeLayout)]
        public async Task<ActionResult> SearchResult(HomeModel model, int page = 1)
        {
            List<HospitalEntity> hospitalList = null;
            IPagedList<HospitalEntity> pagedHospitalList = null;
            try
            {
                // Indicate which button is clicked
                string button = Request[Constants.Button];

                #region Normal Search
                // Normal search form
                if ((string.IsNullOrEmpty(button)) || Constants.NormalSearchForm.Equals(button))
                {
                    ViewBag.SearchValue = model.SearchValue;
                    // Check if input search query is null or empty
                    if (!string.IsNullOrEmpty(model.SearchValue))
                    {
                        // Check if input search value is understandable
                        string[] suggestSentence = StringUtil.CheckVocabulary(model.SearchValue);
                        if (Constants.False.Equals(suggestSentence[0]))
                        {
                            ViewBag.SuggestionSentence = suggestSentence[1];
                        }
                        // Analyze to GIR query
                        await model.GIRQueryAnalyzerAsync(model.SearchValue);

                        // Search hospitals
                        hospitalList = await model.NormalSearchHospital();
                        pagedHospitalList = hospitalList.ToPagedList(page, Constants.PageSize);
                        // Search Query Statistic
                        DataModel.StoreSearchQuery(model.SearchValue, hospitalList.Count);
                    }
                }
                #endregion

                #region Advanced Search
                // Load list of cities
                cityList = await LocationUtil.LoadCityAsync();
                ViewBag.CityList = new SelectList(cityList, Constants.CityID, Constants.CityName);
                // Load list of districts
                districtList = await LocationUtil.LoadDistrictInCityAsync(model.CityID);
                ViewBag.DistrictList = new SelectList(districtList, Constants.DistrictID, Constants.DistrictName);
                // Load list of specialities
                specialityList = await SpecialityUtil.LoadSpecialityAsync();
                ViewBag.SpecialityList = new SelectList(specialityList, Constants.SpecialityID, Constants.SpecialityName);
                // Load list of disease
                diseaseList = new List<Disease>();
                ViewBag.DiseaseList = new SelectList(diseaseList, Constants.DiseaseID, Constants.DiseaseName);
                // Advanced search form
                if (Constants.AdvancedSearchForm.Equals(button))
                {


                    ViewBag.DiseaseName = model.DiseaseName;
                    hospitalList = await model.AdvancedSearchHospital(model.CityID, model.DistrictID,
                        model.SpecialityID, model.DiseaseName);
                    pagedHospitalList = hospitalList.ToPagedList(page, Constants.PageSize);

                    ViewBag.SearchType = Constants.AdvancedSearchForm;
                }
                #endregion

                #region Location Search
                List<SelectListItem> locationTypeListItem = new List<SelectListItem>()
                                                                {
                                                                    new SelectListItem {Value = "2", Text = "Nhập vị trí"},
                                                                    new SelectListItem {Value = "1", Text = "Vị trí hiện tại"}
                                                                };
                ViewBag.LocationTypeList = new SelectList(locationTypeListItem, "Value", "Text", 2);
                List<SelectListItem> radiusListItem = new List<SelectListItem>()
                                                                {
                                                                    new SelectListItem {Value = "0.3", Text = "300 mét"},
                                                                    new SelectListItem {Value = "0.5", Text = "500 mét"},
                                                                    new SelectListItem {Value = "1", Text = "1 km"},
                                                                    new SelectListItem {Value = "3", Text = "3 km"},
                                                                    new SelectListItem {Value = "5", Text = "5 km"},
                                                                    new SelectListItem {Value = "10", Text = "10 km"},
                                                                    new SelectListItem {Value = "15", Text = "15 km"},
                                                                    new SelectListItem {Value = "20", Text = "20 km"}
                                                                };
                ViewBag.RadiusList = new SelectList(radiusListItem, "Value", "Text", 0.3);
                // Location search form
                if (Constants.LocationSearchForm.Equals(button))
                {
                    ViewBag.SearchType = Constants.LocationSearchForm;

                    // Search hospitals
                    double lat = 0;
                    double lng = 0;
                    WebClient client = new WebClient();
                    string coordinate = model.Coordinate;
                    string position = model.Position;

                    if (!(0 < model.Radius && model.Radius <= 20))
                    {
                        model.Radius = 10;
                    }

                    double radius = model.Radius;


                    if (model.LocationType == 1)
                    {
                        if (coordinate != null)
                        {
                            if (coordinate.Split(',').Length > 1)
                            {
                                double.TryParse(coordinate.Split(',')[0], out lat);
                                double.TryParse(coordinate.Split(',')[1], out lng);
                            }
                        }
                    }
                    else if (model.LocationType == 2)
                    {

                        if (!string.IsNullOrEmpty(position))
                        {
                            string geoJsonResult = client.DownloadString(string.Concat(Constants.GeoCodeJsonQuery, position));
                            // Json.Net is really helpful if you have to deal
                            // with Json from .Net http://json.codeplex.com/
                            JObject geoJsonObject = JObject.Parse(geoJsonResult);
                            if (geoJsonObject.Value<string>("status").Equals("OK"))
                            {
                                lat = geoJsonObject["results"].First["geometry"]["location"].Value<double>("lat");
                                lng = geoJsonObject["results"].First["geometry"]["location"].Value<double>("lng");
                            }
                        }

                    }
                    hospitalList = await HomeModel.LocationSearchHospital(lat, lng, radius * 1000);
                    pagedHospitalList = hospitalList.ToPagedList(page, Constants.PageSize);
                    string distanceMatrixUrl = string.Concat("http://maps.googleapis.com/maps/api/distancematrix/json?origins=", lat, ",", lng, "&destinations=");
                    int index = 0;
                    foreach (HospitalEntity hospital in pagedHospitalList)
                    {
                        distanceMatrixUrl += (index == 0 ? string.Empty : "|") + hospital.Coordinate.Split(',')[0].Trim() + "," + hospital.Coordinate.Split(',')[1].Trim();
                        index = -1;
                    }
                    string dMatrixJsonResult = client.DownloadString(distanceMatrixUrl);
                    JObject dMatrixJsonObject = JObject.Parse(dMatrixJsonResult);
                    if (dMatrixJsonObject.Value<string>("status").Equals("OK"))
                    {
                        index = 0;
                        foreach (HospitalEntity hospital in pagedHospitalList)
                        {
                            hospital.Distance = dMatrixJsonObject["rows"].First["elements"].ElementAt(index++)["distance"].Value<double>("value");
                        }

                        model.Coordinate = lat + ", " + lng;
                    }

                }
                #endregion

                // Transfer list of hospitals to Search Result page

                ViewBag.HospitalList = pagedHospitalList;
                ViewBag.JsonHospitalList = JsonConvert.SerializeObject(pagedHospitalList).Replace("\r\n", string.Empty);

                NameValueCollection queryString = System.Web.HttpUtility.ParseQueryString(Request.Url.Query);
                queryString.Remove("page");
                ViewBag.Query = queryString.ToString();

                if (hospitalList.Count == 0)
                {
                    ViewBag.SearchValue = model.SearchValue;
                }

                ViewBag.FeedbackStatus = TempData["FeedbackStatus"];
                ViewBag.FeedbackMessage = TempData["FeedbackMessage"];
            }
            catch (Exception exception)
            {
                LoggingUtil.LogException(exception);
                return RedirectToAction(Constants.SystemFailureHomeAction, Constants.ErrorController);
            }

            // Move to result page
            return View(model);
        }

        #endregion

        /// <summary>
        /// GET: /Home/Index
        /// </summary>
        /// <returns>Task[ActionResult]</returns>
        [LayoutInjecter(Constants.HomeLayout)]
        public async Task<ActionResult> Hospital(int hospitalId = 0)
        {
            try
            {
                HospitalEntity hospital = null;
                if (hospitalId > 0)
                {
                    hospital = await HomeModel.LoadHospitalById(hospitalId);
                    if (hospital != null)
                    {
                        hospital.Services = HomeModel.LoadServicesByHospitalId(hospitalId);
                        hospital.Facilities = HomeModel.LoadFacillitiesByHospitalId(hospitalId);
                        hospital.Specialities = HomeModel.LoadSpecialitiesByHospitalId(hospitalId);
                        ViewBag.SpecialityList = new SelectList(hospital.Specialities, Constants.SpecialityID, Constants.SpecialityName);
                        ViewBag.RateActionStatus = TempData["RateActionStatus"];
                        ViewBag.RateActionMessage = TempData["RateActionMessage"];
                        ViewBag.FeedbackStatus = TempData["FeedbackStatus"];
                        ViewBag.FeedbackMessage = TempData["FeedbackMessage"];
                        ViewBag.HospitalEntity = hospital;
                        ViewBag.DoctorList = DoctorModel.LoadDoctorListByHospitalId(hospitalId);
                        ViewBag.Photos = HomeModel.LoadPhotosByHospitalId(hospitalId);
                    }
                    else
                    {
                        return RedirectToAction(Constants.IndexAction, Constants.HomeController);
                    }
                }
                else
                {
                    return RedirectToAction(Constants.IndexAction, Constants.HomeController);
                }

            }
            catch (Exception exception)
            {
                LoggingUtil.LogException(exception);
                return RedirectToAction(Constants.SystemFailureHomeAction, Constants.ErrorController);
            }
            return View();
        }

        [HttpPost]
        [Authorize(Roles = Constants.UserRoleName)]
        public ActionResult RateHospital(int id = 0, int score = 0)
        {
            try
            {
                if (Session["RATING_TIME"] == null)
                {
                    Session["RATING_TIME"] = 0;
                }

                int ratingTime = (int)Session["RATING_TIME"];
                Session["RATING_TIME"] = ++ratingTime;

                if (ratingTime > 3)
                {
                    RecaptchaVerificationHelper recaptchaHelper = this.GetRecaptchaVerificationHelper();

                    if (String.IsNullOrEmpty(recaptchaHelper.Response))
                    {
                        TempData["RateActionStatus"] = false;
                        TempData["RateActionMessage"] = "Vui lòng nhập mã bảo mật bên dưới.";

                        return RedirectToAction(Constants.HospitalAction, Constants.HomeController, new { hospitalId = id, redirect = "yes" });
                    }

                    RecaptchaVerificationResult recaptchaResult = recaptchaHelper.VerifyRecaptchaResponse();

                    if (recaptchaResult != RecaptchaVerificationResult.Success)
                    {
                        TempData["RateActionStatus"] = false;
                        TempData["RateActionMessage"] = "Vui lòng nhập lại mã bảo mật bên dưới.";

                        return RedirectToAction(Constants.HospitalAction, Constants.HomeController, new { hospitalId = id, redirect = "yes" });
                    }
                }

                string email = User.Identity.Name.Split(Char.Parse(Constants.Minus))[0];

                int userId = AccountModel.LoadUserIdByEmail(email);

                bool check = HomeModel.RateHospital(userId, id, score);
                if (!check)
                {
                    TempData["RateActionStatus"] = false;
                    TempData["RateActionMessage"] = "Vui lòng thử lại sau ít phút.";
                }
                TempData["RateActionStatus"] = true;
                return RedirectToAction(Constants.HospitalAction, Constants.HomeController, new { hospitalId = id, redirect = "yes" });

            }
            catch (Exception exception)
            {
                LoggingUtil.LogException(exception);
                return RedirectToAction(Constants.SystemFailureHomeAction, Constants.ErrorController);
            }
        }

        #region Feedback
        public async Task<ActionResult> Feedback(FeedBackModel model, int hospitalId = 0)
        {
            List<FeedbackType> feebackTypeList = FeedBackModel.LoadFeedbeackTypeList();
            if (FeedBackModel.IsAssignedHospital(hospitalId))
            {
                HospitalEntity hospitalEntity = await HomeModel.LoadHospitalById(hospitalId);
                feebackTypeList.Remove(feebackTypeList.First());
                feebackTypeList.Remove(feebackTypeList.First());
                feebackTypeList.Remove(feebackTypeList.First());
                model.Header = hospitalEntity.Hospital_Name;
                model.HospitalID = hospitalId;
            }
            else
            {
                feebackTypeList.Remove(feebackTypeList.Last());
                feebackTypeList.Remove(feebackTypeList.Last());
            }
            ViewBag.FeedbackTypeList = new SelectList(feebackTypeList, Constants.FeedbackType, Constants.FeedbackTypeName);
            model.Email = User.Identity.Name.Split(Char.Parse(Constants.Minus))[0];
            return PartialView(model);
        }

        [HttpPost]
        public async Task<ActionResult> Feedback(FeedBackModel model)
        {
            try
            {
                RecaptchaVerificationHelper recaptchaHelper = this.GetRecaptchaVerificationHelper();

                if (String.IsNullOrEmpty(recaptchaHelper.Response))
                {
                    TempData["FeedbackStatus"] = false;
                    TempData["FeedbackMessage"] = "Vui lòng nhập mã bảo mật bên dưới.";
                    return Redirect(Request.UrlReferrer.AbsoluteUri);
                }

                RecaptchaVerificationResult recaptchaResult = recaptchaHelper.VerifyRecaptchaResponse();

                if (recaptchaResult != RecaptchaVerificationResult.Success)
                {
                    TempData["FeedbackStatus"] = false;
                    TempData["FeedbackMessage"] = "Vui lòng nhập lại mã bảo mật bên dưới.";
                    return Redirect(Request.UrlReferrer.AbsoluteUri);
                }
                TempData["FeedbackStatus"] = model.InsertNewFeedback();
                return Redirect(Request.UrlReferrer.AbsoluteUri);
            }
            catch (Exception exception)
            {
                LoggingUtil.LogException(exception);
                return RedirectToAction(Constants.SystemFailureHomeAction, Constants.ErrorController);
            }
        }
        #endregion

    }
}
