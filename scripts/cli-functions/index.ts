import addTrustedKey from "./add-trusted-key/add-trusted-key";
import createCampaign from "./campaigns/create-campaign";
import listCampaigns from "./campaigns/list-campaigns";
import addContribution from "./contributions/add-contribution";
import listContributions from "./contributions/list-contributions";
import help from "./help";
import mintToken from "./token/mint-token";
import transferToken from "./token/transfer-token";
import register from "./token/register";
import subscribe from "./subscription/subscribe";
import updatePrice from "./subscription/update-price";
import main from "./main";
import showAccountInformation from "./account/showAccountInformation";
import publish from "./automation/publish";
import faucet from "./token/faucet";
import getAllActiveCampaigns from "./campaigns/get_all_active_campaigns";
import lastCreatedCampaign from "./campaigns/last_created_campaign";

export default {
  addTrustedKey,
  createCampaign,
  listCampaigns,
  addContribution,
  listContributions,
  help,
  mintToken,
  transferToken,
  register,
  subscribe,
  updatePrice,
  main,
  showAccountInformation,
  publish,
  faucet,
  getAllActiveCampaigns,
  lastCreatedCampaign,
};
