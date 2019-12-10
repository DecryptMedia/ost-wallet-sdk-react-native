// Working IMPORTS.
import React, {PureComponent} from 'react';
import {Alert, FlatList, Linking, Platform, Text, TouchableWithoutFeedback, View} from 'react-native';
import OstWalletSdkHelper from "../helpers/OstWalletSdkHelper";

// To-Be-Reomved.
import inlineStyle from './styles'
// import {LoadingModal} from '../../theme/components/LoadingModalCover';
// import {ostSdkErrors} from "../../services/OstSdkErrors";
// import CameraPermissionsApi from "../../services/CameraPermissionsApi";

// Fixed.
import {optionIds, WalletSettingsController} from './WalletSettingsController';
let AndroidOpenSettings = null;
import('react-native-android-open-settings').then((pack) => {
  AndroidOpenSettings = pack.default;
}).catch( (err) => {
  //Ignore. 
});

/// REMOVED
// import BackArrow from '../CommonComponents/BackArrow';
// import Colors from "../../theme/styles/Colors";
// import DeviceInfo from 'react-native-device-info';
// import CurrentUser from "../../models/CurrentUser";

class SettingsComponent extends PureComponent {
  constructor(props) {
    super(props);
    this.state = {
      list: [],
      refreshing: false,
    };

    
    let ostUserId = this.props.ostUserId;
    let delegate = this.props.ostWalletUIWorkflowCallback;

    /// If using react-navigation.
    let navigation = this.props.navigation;
    if ( navigation && navigation.getParam ) {
      ostUserId = ostUserId || navigation.getParam("ostUserId");
      delegate  = delegate || navigation.getParam("ostWalletUIWorkflowCallback");
    }

    this.controller = new WalletSettingsController(ostUserId, delegate);
    this._initiateEventTextMap()
  }

  _initiateEventTextMap() {
    this.eventLoaderTextMap = {};

    this._createEventLoaderData(
      optionIds.addSession,
      "Adding Session",
      "Waiting for confirmation",
      "Session added");

    this._createEventLoaderData(
      optionIds.updateBiometricPreference,
      "Updating Biometric",
      "Waiting for confirmation",
      "Biometric updated");

    this._createEventLoaderData(
      optionIds.resetPin,
      "Resetting PIN...",
      "Waiting for confirmation",
      "PIN has been successfully reset");

    this._createEventLoaderData(
      optionIds.recoverDevice,
      "Recovering device",
      "Waiting for confirmation",
      "Device recovery initiated");

    this._createEventLoaderData(
      optionIds.abortRecovery,
      "Cancelling recovery",
      "Waiting for confirmation",
      "Aborted recovery");

    this._createEventLoaderData(
      optionIds.viewMnemonics,
      "",
      "",
      "");

    this._createEventLoaderData(
      optionIds.authorizeWithQR,
      "Authorizing device",
      "Waiting for confirmation",
      "Device authorized");


    this._createEventLoaderData(
      optionIds.authorizeWithMnemonics,
      "Authorizing device",
      "Waiting for confirmation",
      "Device authorized");

    this._createEventLoaderData(
      optionIds.showQR,
      "",
      "Waiting for confirmation",
      "Device authorized");
  }

  _createEventLoaderData(id, startText, ackText, successText){
    let loaderData = {
      id: id,

      startText: startText,

      // Acknowledgement text
      acknowledgedText: ackText,

      // Success Text
      successText: successText,
    };

    this.eventLoaderTextMap[ id ] = loaderData;
    return loaderData;
  }

  _getFlowCompleteText() {
    let text = this.eventLoaderTextMap[this.workflowInfo.workflowOptionId].successText;
    return text
  }

  _getFlowStartedText() {
    let text = this.eventLoaderTextMap[this.workflowInfo.workflowOptionId].startText;
    return text
  }

  _getRequestAcknowledgedText() {
    let text = this.eventLoaderTextMap[this.workflowInfo.workflowOptionId].acknowledgedText;
    return text
  }

  _getFlowFailedText(workflowContext, ostError) {
    /// TODO bubble ostSdkErrors was here.
    // return ostSdkErrors.getErrorMessage(workflowContext, ostError)
    return "";
  }

  componentDidMount() {
    this.refreshList();
  }

  refreshList = (onFetch) => {
    if (this.state.refreshing) {
      return
    }
    this.setState({
      refreshing: true
    })
    this.controller.refresh((optionsData) => {
      this.setState({
        list: optionsData,
        refreshing: false
      });
      if (onFetch) {
        onFetch(optionsData)
      }
    }, true);
  };

  onSettingItemTapped = (item) => {
    this._processTappedOption(item);
  };

  async _processTappedOption(item) {
    if ( optionIds.walletDetails === item.id ) {
      this.props.navigation.navigate('WalletDetails');
      return;
    } else if (item.id === optionIds.authorizeWithQR) {
      /// TODO bubble CameraPermissionsApi.requestPermission was here.
      // let cameraResult = await CameraPermissionsApi.requestPermission('camera');
      let cameraResult = "";
      if ((cameraResult == 'denied' || cameraResult == 'restricted')) {
        /// TODO bubble LoadingModal was here.

        // LoadingModal.showFailureAlert("Allow access to your camera to scan QR", '', 'Enable Camera Access', (isBtnTapped) => {
        //   if (isBtnTapped) {
        //     this.enableAccess();
        //   }
        // });

        return;
      }
    }
    this._perfromWorkflow(item)
  }

  _perfromWorkflow(item) {
    let workflowInfo = this.controller.perform(item.id);
    if ( workflowInfo ) {
      this.onWorkflowStarted( workflowInfo );
    } else {
      //Some coding error occurred.
      console.log("PepoError", "ws_indx_osit_1", "Some coding error occurred");
    }
  }

  enableAccess() {
    if (Platform.OS == 'android') {
      if (AndroidOpenSettings) {
        AndroidOpenSettings.appDetailsSettings();
      }
    } else {
      Linking.canOpenURL('app-settings:')
        .then((supported) => {
          if (!supported) {
            console.log("Can't handle settings url");
          } else {
            return Linking.openURL('app-settings:');
          }
        })
        .catch((err) => console.error('An error occurred', err));
    }
  }

  onWorkflowStarted = (workflowInfo) => {
    this.workflowInfo = workflowInfo;
    // Show loader.
    //LoadingModal.show('');

    // Subscribe to events.
    this.controller.setUIDelegate(this);
  };

  requestAcknowledged = (ostWorkflowContext , ostContextEntity) => {
    // LoadingModal.show(this._getRequestAcknowledgedText())
  };

  flowComplete = (ostWorkflowContext , ostContextEntity) => {
    this.refreshList(() => {
      if (this.canShowAlert(ostWorkflowContext)) {
        let text = this._getFlowCompleteText();
        // LoadingModal.showSuccessAlert(text);
      }else {
        // LoadingModal.hide()
      }

    });
  };

  onUnauthorized = (ostWorkflowContext , ostError) => {
    /// TODO bubble LoadingModal was here.
    
    // LoadingModal.showFailureAlert("Device is not authorized. Please authorize device again.", null, "Logout", () => {
    //   //TODO bubble - Deal with this.
      
    //   // CurrentUser.logout({
    //   //   device_id: DeviceInfo.getUniqueID()
    //   // });
    // })
  };

  saltFetchFailed = (ostWorkflowContext , ostError) => {
    /// TODO bubble LoadingModal was here.

    // LoadingModal.showFailureAlert("There is some issue while fetching salt. Please retry", null, "Retry", (isButtonTapped) => {
    //   if (isButtonTapped) {
    //     let retryItem = this.controller.optionsMap[this.workflowInfo.workflowOptionId];
    //     this.onSettingItemTapped(retryItem);
    //   }
    // })
  };

  userCancelled = (ostWorkflowContext , ostError) => {
    /// TODO bubble LoadingModal was here.

    // LoadingModal.hide();
  };

  deviceTimeOutOfSync = (ostWorkflowContext , ostError) => {
    this.workflowFailed(ostWorkflowContext, ostError);
  };

  workflowFailed = (ostWorkflowContext , ostError) => {
    let text = this._getFlowFailedText(ostWorkflowContext, ostError);
    // LoadingModal.showFailureAlert(text, null, "Dismiss");
  };

  canShowAlert(workflowContext) {
    if (workflowContext.WORKFLOW_TYPE === 'GET_DEVICE_MNEMONICS') {
      return false
    }

    return true
  }

  _keyExtractor = (item, index) => `id_${item.id}`;

  _renderItem = ({ item, index }) => {
    return (
      <TouchableWithoutFeedback onPress={() => this.onSettingItemTapped(item)}>
        <View style={inlineStyle.listComponent}>
        <Text style={inlineStyle.title}>{item.heading}</Text>
        <Text style={inlineStyle.subtitle}>{item.description}</Text>
        </View>
      </TouchableWithoutFeedback>
    );
  };

  render() {
    return (
      <View style= {inlineStyle.list}>
        <FlatList
          data={this.state.list}
          refreshing={this.state.refreshing}
          renderItem={this._renderItem}
          keyExtractor={this._keyExtractor}
          visible={false}
          onRefresh={this.refreshList}
        />
      </View>
    );
  }
}

export default SettingsComponent;
