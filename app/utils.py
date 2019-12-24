import torch


def load_model(model_name):
    from model import STAGE1_G, STAGE2_G
    stage1_g = STAGE1_G()
    netG = STAGE2_G(stage1_g)
    state_dict = torch.load(model_name, map_location=lambda storage, loc: storage)
    netG.load_state_dict(state_dict)
    return netG