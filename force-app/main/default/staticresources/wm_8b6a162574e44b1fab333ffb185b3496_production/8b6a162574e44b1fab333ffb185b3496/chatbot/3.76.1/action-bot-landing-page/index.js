"use strict";

function ownKeys(object, enumerableOnly) { var keys = Object.keys(object); if (Object.getOwnPropertySymbols) { var symbols = Object.getOwnPropertySymbols(object); enumerableOnly && (symbols = symbols.filter(function (sym) { return Object.getOwnPropertyDescriptor(object, sym).enumerable; })), keys.push.apply(keys, symbols); } return keys; }

function _objectSpread(target) { for (var i = 1; i < arguments.length; i++) { var source = null != arguments[i] ? arguments[i] : {}; i % 2 ? ownKeys(Object(source), !0).forEach(function (key) { _defineProperty(target, key, source[key]); }) : Object.getOwnPropertyDescriptors ? Object.defineProperties(target, Object.getOwnPropertyDescriptors(source)) : ownKeys(Object(source)).forEach(function (key) { Object.defineProperty(target, key, Object.getOwnPropertyDescriptor(source, key)); }); } return target; }

function _defineProperty(obj, key, value) { if (key in obj) { Object.defineProperty(obj, key, { value: value, enumerable: true, configurable: true, writable: true }); } else { obj[key] = value; } return obj; }

function _typeof(obj) { "@babel/helpers - typeof"; return _typeof = "function" == typeof Symbol && "symbol" == typeof Symbol.iterator ? function (obj) { return typeof obj; } : function (obj) { return obj && "function" == typeof Symbol && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : typeof obj; }, _typeof(obj); }

function _slicedToArray(arr, i) { return _arrayWithHoles(arr) || _iterableToArrayLimit(arr, i) || _unsupportedIterableToArray(arr, i) || _nonIterableRest(); }

function _nonIterableRest() { throw new TypeError("Invalid attempt to destructure non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."); }

function _unsupportedIterableToArray(o, minLen) { if (!o) return; if (typeof o === "string") return _arrayLikeToArray(o, minLen); var n = Object.prototype.toString.call(o).slice(8, -1); if (n === "Object" && o.constructor) n = o.constructor.name; if (n === "Map" || n === "Set") return Array.from(o); if (n === "Arguments" || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)) return _arrayLikeToArray(o, minLen); }

function _arrayLikeToArray(arr, len) { if (len == null || len > arr.length) len = arr.length; for (var i = 0, arr2 = new Array(len); i < len; i++) { arr2[i] = arr[i]; } return arr2; }

function _iterableToArrayLimit(arr, i) { var _i = arr == null ? null : typeof Symbol !== "undefined" && arr[Symbol.iterator] || arr["@@iterator"]; if (_i == null) return; var _arr = []; var _n = true; var _d = false; var _s, _e; try { for (_i = _i.call(arr); !(_n = (_s = _i.next()).done); _n = true) { _arr.push(_s.value); if (i && _arr.length === i) break; } } catch (err) { _d = true; _e = err; } finally { try { if (!_n && _i["return"] != null) _i["return"](); } finally { if (_d) throw _e; } } return _arr; }

function _arrayWithHoles(arr) { if (Array.isArray(arr)) return arr; }

function asyncGeneratorStep(gen, resolve, reject, _next, _throw, key, arg) { try { var info = gen[key](arg); var value = info.value; } catch (error) { reject(error); return; } if (info.done) { resolve(value); } else { Promise.resolve(value).then(_next, _throw); } }

function _asyncToGenerator(fn) { return function () { var self = this, args = arguments; return new Promise(function (resolve, reject) { var gen = fn.apply(self, args); function _next(value) { asyncGeneratorStep(gen, resolve, reject, _next, _throw, "next", value); } function _throw(err) { asyncGeneratorStep(gen, resolve, reject, _next, _throw, "throw", err); } _next(undefined); }); }; }

// @flow

/* istanbul ignore file */
function onDocumentReady(callback) {
  if (document.readyState === 'complete' || document.readyState === 'interactive') {
    callback();
  } else {
    document.addEventListener('DOMContentLoaded', callback);
  }
}

onDocumentReady(function () {
  var origin = window.location.origin;
  var API_CONFIG = {
    cdnUrl: origin.includes('localhost') ? 'https://cdn.walkmeqa.com' : origin,
    papiUrl: "https://".concat(origin.includes('eu') ? 'eu-papi' : 'papi', ".walkme").concat(origin.includes('localhost') || origin.includes('walkmeqa') ? 'qa' : '', ".com")
  };
  var PREFIX = 'wm-ab-';
  var VALUES_LIFE_TIME = 60 * 10;
  var supportedAppTypes = ['START_WALKTHRU', 'START_SMARTWALKTHRU', 'SMARTWALKTHRU', 'WALKTHRU', 'SURVEY', 'SHOUTOUT', 'RESOURCE', 'SHUTTLE', 'WEB_INTEGRATION', 'STORE_DATA'];
  var appTypesWithDataMapping = supportedAppTypes; // According to EUI they all have dataMapping

  var envIdToEnvPath = {
    0: '',
    3: '/test',
    95: '/success',
    32: '/success'
  };
  var params = new URLSearchParams(window.location.search);

  var paramsAreValid = function paramsAreValid(searchParams) {
    var requiredParamKeys = ['userGuid', 'jwt', 'envId', 'botId', 'conversationId', 'dialogId', 'nodeId'];
    return requiredParamKeys.every(function (key) {
      return searchParams.has(key);
    }) && envIdToEnvPath.hasOwnProperty(searchParams.get('envId'));
  };

  var getDialog = /*#__PURE__*/function () {
    var _ref2 = _asyncToGenerator( /*#__PURE__*/regeneratorRuntime.mark(function _callee(_ref) {
      var botId, conversationId, dialogId, envId, jwt, url;
      return regeneratorRuntime.wrap(function _callee$(_context) {
        while (1) {
          switch (_context.prev = _context.next) {
            case 0:
              botId = _ref.botId, conversationId = _ref.conversationId, dialogId = _ref.dialogId, envId = _ref.envId, jwt = _ref.jwt;
              url = "".concat(API_CONFIG.papiUrl, "/chatbot/bots/").concat(botId, "/conversations/").concat(conversationId, "/dialogs/").concat(dialogId);
              return _context.abrupt("return", featchDataFromServer(url, envId, jwt));

            case 3:
            case "end":
              return _context.stop();
          }
        }
      }, _callee);
    }));

    return function getDialog(_x) {
      return _ref2.apply(this, arguments);
    };
  }();

  var getNode = function getNode(_ref3) {
    var botId = _ref3.botId,
        conversationId = _ref3.conversationId,
        dialogId = _ref3.dialogId,
        nodeId = _ref3.nodeId,
        envId = _ref3.envId,
        jwt = _ref3.jwt,
        bbCodes = _ref3.bbCodes;
    var url = "".concat(API_CONFIG.papiUrl, "/chatbot/bots/").concat(botId, "/conversations/").concat(conversationId, "/dialogs/").concat(dialogId, "/nodes/").concat(nodeId);

    if (bbCodes) {
      url = url + "?bbCodes=".concat(bbCodes);
    }

    return featchDataFromServer(url, envId, jwt);
  };

  var featchDataFromServer = /*#__PURE__*/function () {
    var _ref4 = _asyncToGenerator( /*#__PURE__*/regeneratorRuntime.mark(function _callee2(url, envId, jwt) {
      var fetchData;
      return regeneratorRuntime.wrap(function _callee2$(_context2) {
        while (1) {
          switch (_context2.prev = _context2.next) {
            case 0:
              _context2.next = 2;
              return new Promise(function (resolve) {
                wmjQuery.ajax({
                  url: url,
                  type: 'GET',
                  beforeSend: function beforeSend(xhr) {
                    xhr.setRequestHeader('content-type', 'application/json');
                    xhr.setRequestHeader('authorization', "Bearer ".concat(jwt));
                    xhr.setRequestHeader('x-wmab-wmenv', envId);
                  },
                  success: resolve
                });
              });

            case 2:
              fetchData = _context2.sent;
              return _context2.abrupt("return", fetchData);

            case 4:
            case "end":
              return _context2.stop();
          }
        }
      }, _callee2);
    }));

    return function featchDataFromServer(_x2, _x3, _x4) {
      return _ref4.apply(this, arguments);
    };
  }();

  var normalizeAnswers = function normalizeAnswers(rawAnswers, nodeData) {
    var _nodeData$settings = nodeData.settings,
        settings = _nodeData$settings === void 0 ? {} : _nodeData$settings;
    var app = settings.app;
    var answers = Object.entries(rawAnswers).reduce(function (acc, _ref5) {
      var _ref6 = _slicedToArray(_ref5, 2),
          key = _ref6[0],
          descriptor = _ref6[1];

      if (descriptor && descriptor.type === 'conversationVariable') {
        return _typeof(descriptor.value) === 'object' ? _objectSpread(_objectSpread({}, acc), Object.entries(descriptor.value).reduce(function (innerAcc, _ref7) {
          var _ref8 = _slicedToArray(_ref7, 2),
              innerKey = _ref8[0],
              innerValue = _ref8[1];

          return _objectSpread(_objectSpread({}, innerAcc), {}, _defineProperty({}, innerKey, {
            value: innerValue,
            nodeId: Number(key)
          }));
        }, {})) : acc;
      }

      return _objectSpread(_objectSpread({}, acc), {}, _defineProperty({}, key, _objectSpread(_objectSpread({}, descriptor), {}, {
        nodeId: Number(key)
      })));
    }, {});

    if (appTypesWithDataMapping.includes(app)) {
      var _nodeData$dataMapping = nodeData.dataMapping,
          dataMapping = _nodeData$dataMapping === void 0 ? {} : _nodeData$dataMapping;
      return Object.entries(dataMapping).reduce(function (acc, _ref9) {
        var _ref10 = _slicedToArray(_ref9, 2),
            key = _ref10[0],
            value = _ref10[1];

        return _objectSpread(_objectSpread({}, acc), {}, _defineProperty({}, value, answers[key]));
      }, {});
    }

    return {};
  };

  var runDeployable = /*#__PURE__*/function () {
    var _ref11 = _asyncToGenerator( /*#__PURE__*/regeneratorRuntime.mark(function _callee3(params) {
      var jwt, botId, conversationId, dialogId, envId, nodeId, bbCodes, classWalkMeAPI, shoutOutsManager, shuttlesManager, siteConfigManager, appTypeToWmActionHandler, _yield$getDialog, rawAnswers, _ref12, jsonSettings, _ref13, actionBotCustomSettings, rawNode, answers, destinationUrl, accountsToSync, _ref14, syncSwtDataToOtherAccounts, syncSwtDataMatchingRecords, accountsGuids;

      return regeneratorRuntime.wrap(function _callee3$(_context3) {
        while (1) {
          switch (_context3.prev = _context3.next) {
            case 0:
              jwt = params.get('jwt');
              botId = params.get('botId');
              conversationId = params.get('conversationId');
              dialogId = params.get('dialogId');
              envId = params.get('envId');
              nodeId = params.get('nodeId');
              bbCodes = params.get('bbCodes');
              classWalkMeAPI = window._walkmeInternals.ctx.get('ClassWalkMeAPI');
              shoutOutsManager = window._walkmeInternals.ctx.get('ShoutOutsManager');
              shuttlesManager = window._walkmeInternals.ctx.get('ShuttlesManager');
              siteConfigManager = window._walkmeInternals.ctx.get('SiteConfigManager').get();
              appTypeToWmActionHandler = {
                START_WALKTHRU: function START_WALKTHRU(id) {
                  return classWalkMeAPI.startFlowById(id);
                },
                START_SMARTWALKTHRU: function START_SMARTWALKTHRU(id) {
                  return classWalkMeAPI.startFlowById(id);
                },
                SMARTWALKTHRU: function SMARTWALKTHRU(id) {
                  return classWalkMeAPI.startFlowById(id);
                },
                WALKTHRU: function WALKTHRU(id) {
                  return classWalkMeAPI.startWalkthruById(id);
                },
                SURVEY: function SURVEY(id) {
                  return classWalkMeAPI.startSurveyById(id);
                },
                SHOUTOUT: function SHOUTOUT(id) {
                  return shoutOutsManager.activateById(id);
                },
                RESOURCE: function RESOURCE(id) {
                  return classWalkMeAPI.startContentById(id);
                },
                SHUTTLE: function SHUTTLE(id) {
                  return shuttlesManager.activateById(id);
                }
              };
              _context3.prev = 12;
              _context3.next = 15;
              return getDialog({
                botId: botId,
                conversationId: conversationId,
                dialogId: dialogId,
                envId: envId,
                jwt: jwt
              });

            case 15:
              _yield$getDialog = _context3.sent;
              rawAnswers = _yield$getDialog.data;
              _ref12 = siteConfigManager || {}, jsonSettings = _ref12.Custom;
              _ref13 = jsonSettings || {}, actionBotCustomSettings = _ref13.actionbot;
              _context3.next = 21;
              return getNode({
                botId: botId,
                conversationId: conversationId,
                dialogId: dialogId,
                nodeId: nodeId,
                envId: envId,
                jwt: jwt,
                bbCodes: bbCodes
              });

            case 21:
              rawNode = _context3.sent;
              answers = normalizeAnswers(rawAnswers, rawNode);

              if (!(rawNode.settings.webSystemGuid && rawNode.settings.destinationUrl && rawNode.settings.permalink)) {
                _context3.next = 29;
                break;
              }

              saveAnswersToStorage(answers, actionBotCustomSettings, rawNode.settings.webSystemGuid);
              refreshGetData(answers, appTypeToWmActionHandler, rawNode, {
                botId: botId,
                conversationId: conversationId,
                dialogId: dialogId
              });
              destinationUrl = rawNode.customDestinationUrl ? rawNode.customDestinationUrl : rawNode.settings.destinationUrl;
              location.href = "".concat(destinationUrl).concat(rawNode.settings.permalink);
              return _context3.abrupt("return");

            case 29:
              accountsToSync = [undefined];

              try {
                _ref14 = actionBotCustomSettings || {}, syncSwtDataToOtherAccounts = _ref14.syncSwtDataToOtherAccounts;

                if (syncSwtDataToOtherAccounts && syncSwtDataToOtherAccounts.length) {
                  syncSwtDataMatchingRecords = syncSwtDataToOtherAccounts.filter(function (item) {
                    if (Array.isArray(item.conversationId)) {
                      return item.conversationId.map(Number).indexOf(Number(conversationId)) > -1;
                    }

                    return Number(item.conversationId) === Number(conversationId);
                  });

                  if (syncSwtDataMatchingRecords && syncSwtDataMatchingRecords.length) {
                    accountsGuids = syncSwtDataMatchingRecords.reduce(function (acc, item) {
                      if (item && item.accountGuids && item.accountGuids.length) {
                        return acc.concat(item.accountGuids);
                      }

                      return acc;
                    }, []);
                    accountsToSync = accountsToSync.concat(accountsGuids);
                  }
                }
              } catch (e) {
                console.error(e);
              }

              accountsToSync.forEach(function (account) {
                saveAnswersToStorage(answers, actionBotCustomSettings, account);
              });
              refreshGetData(answers, appTypeToWmActionHandler, rawNode, {
                botId: botId,
                conversationId: conversationId,
                dialogId: dialogId
              });
              _context3.next = 39;
              break;

            case 35:
              _context3.prev = 35;
              _context3.t0 = _context3["catch"](12);
              console.error(_context3.t0);
              console.warn('Unable to launch deployable. Please reload the page or check parameters validity.');

            case 39:
            case "end":
              return _context3.stop();
          }
        }
      }, _callee3, null, [[12, 35]]);
    }));

    return function runDeployable(_x5) {
      return _ref11.apply(this, arguments);
    };
  }();

  var saveAnswersToStorage = function saveAnswersToStorage(answers, actionBotCustomSettings, account) {
    var clientStorageManager = window._walkmeInternals.ctx.get('ClientStorageManager');

    Object.entries(answers).forEach(function (_ref15) {
      var _ref16 = _slicedToArray(_ref15, 2),
          key = _ref16[0],
          value = _ref16[1];

      var ttl;

      try {
        var swtDataTTL = actionBotCustomSettings && actionBotCustomSettings.swtDataTTL;

        if (swtDataTTL && swtDataTTL.length) {
          var node = swtDataTTL.find(function (item) {
            if (Array.isArray(item.nodeId)) {
              return item.nodeId.map(Number).indexOf(value.nodeId) > -1;
            }

            return Number(item.nodeId) === value.nodeId;
          });
          ttl = Number(node && node.ttl);
        }
      } catch (e) {
        console.error(e);
      }

      clientStorageManager.saveData("".concat(PREFIX).concat(key), value, VALUES_LIFE_TIME, account);
    });
    clientStorageManager.saveData("".concat(PREFIX, "web-integration"), {
      forceLoad: 1
    }, VALUES_LIFE_TIME, account);
  };

  var refreshGetData = function refreshGetData(answers, appTypeToWmActionHandler, rawNode, payloadOptions) {
    var clientStorageManager = window._walkmeInternals.ctx.get('ClientStorageManager');

    var commonEvents = window._walkmeInternals.ctx.get('CommonEvents');

    clientStorageManager.refreshGetData(null, /*#__PURE__*/_asyncToGenerator( /*#__PURE__*/regeneratorRuntime.mark(function _callee4() {
      var nodeSettings, wmActionHandler, payload;
      return regeneratorRuntime.wrap(function _callee4$(_context4) {
        while (1) {
          switch (_context4.prev = _context4.next) {
            case 0:
              nodeSettings = rawNode.settings || {};
              wmActionHandler = appTypeToWmActionHandler[nodeSettings.app];

              if (!(wmActionHandler && nodeSettings.id)) {
                _context4.next = 8;
                break;
              }

              payload = {
                settings: nodeSettings,
                answers: answers,
                options: payloadOptions
              };
              commonEvents.raiseEvent('WM_BOT_DUI_ACTION', payload);

              window.open = function (url) {
                location.href = url;
              };

              _context4.next = 8;
              return wmActionHandler(nodeSettings.id);

            case 8:
            case "end":
              return _context4.stop();
          }
        }
      }, _callee4);
    })));
  };

  var loadUserSnippet = function loadUserSnippet(params, onReadyCallback) {
    window.walkme_ready = onReadyCallback;
    var userGuid = params.get('userGuid');
    var envPath = envIdToEnvPath[params.get('envId')];
    var snippetSrc = "".concat(API_CONFIG.cdnUrl, "/users/").concat(userGuid).concat(envPath, "/walkme_").concat(userGuid, "_https.js");
    var walkmeScript = document.createElement('script');
    walkmeScript.type = 'text/javascript';
    walkmeScript.src = snippetSrc;
    document.body.append(walkmeScript);
  };

  var forceProxyStorage = function forceProxyStorage() {
    var exDate = new Date();
    exDate.setTime(exDate.getTime() + 100000);
    var expireString = '; expires=' + exDate.toUTCString() + '; path=/';
    document.cookie = 'wm-stt=proxy' + expireString;
  };

  if (paramsAreValid(params)) {
    forceProxyStorage();
    loadUserSnippet(params, function () {
      return runDeployable(params);
    });
  } else {
    console.warn('Required parameter is missing or malformed.');
  }
});
//# sourceMappingURL=index.js.map