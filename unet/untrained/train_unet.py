import torch
import torch.nn as nn
import numpy as np
import scipy.io as sio
import matplotlib.pyplot as plt
from model import PhysicsUNet
from loss  import physics_loss

import os
import imageio

# parameters
p = 16
lr = 1e-3
num_iter = 5000
alpha = 1e-4
device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')

input_path  = f'unet/inputs/unet_input_p{p}.mat'
output_path = f'unet/outputs/O_hat_p{p}.mat'
print(f'Device: {device}')



# loading data
data   = sio.loadmat(input_path)
O_star = data['O_star'].astype(np.float32)
H_mat  = data['H'].astype(np.float32)
Q_vec  = data['Q'].astype(np.float32).flatten()
gt     = data['img'].astype(np.float32)



with torch.no_grad():
    test_input = torch.tensor(O_star).unsqueeze(0).unsqueeze(0)
    test_model = PhysicsUNet()
    test_out   = test_model(test_input)
    O_flat_test = test_out.squeeze().reshape(-1)
    Q_pred_test = torch.tensor(H_mat) @ O_flat_test
    data_t  = torch.norm(torch.tensor(Q_vec) - Q_pred_test) ** 2
    print(f'\nDiagnosis:')
    print(f'Q_measured range:   {Q_vec.min():.4f} to {Q_vec.max():.4f}')
    print(f'Q_predicted range:  {Q_pred_test.min():.4f} to {Q_pred_test.max():.4f}')
    print(f'data_term only:     {data_t.item():.2f}')
    print(f'num elements in Q:  {len(Q_vec)}')



O_star = O_star - O_star.min()
O_star = O_star / (O_star.max() + 1e-8)
gt     = gt     - gt.min()
gt     = gt     / (gt.max() + 1e-8)
gt_t = torch.tensor(gt).unsqueeze(0).unsqueeze(0).to(device)




Q_recomputed = H_mat @ O_star.flatten()
print(f'Q from H*O_star: min={Q_recomputed.min():.4f} max={Q_recomputed.max():.4f}')
print(f'Q measured:      min={Q_vec.min():.4f}      max={Q_vec.max():.4f}')

# scale Q_measured to match H*O_star range
Q_scale = Q_recomputed.max() + 1e-8
Q_vec   = Q_vec / Q_scale
H_mat   = H_mat / Q_scale    

print(f'After scaling:')
print(f'H: max={H_mat.max():.4f}')
print(f'Q: max={Q_vec.max():.4f}')



O_star_t = torch.tensor(O_star).unsqueeze(0).unsqueeze(0).to(device)
H_t      = torch.tensor(H_mat).to(device)
Q_t      = torch.tensor(Q_vec).to(device)

# model
model     = PhysicsUNet().to(device)
optimizer = torch.optim.Adam(model.parameters(), lr=lr)
scheduler = torch.optim.lr_scheduler.ReduceLROnPlateau(
            optimizer, patience=200, factor=0.5)

with torch.no_grad():
    model.out.bias.fill_(float(O_star.mean()))
    nn.init.xavier_normal_(model.out.weight, gain=0.1)


print(f'\nShape check:')
print(f'H cols={H_mat.shape[1]} | O_flat len={O_star.flatten().shape[0]}')
print(f'H rows={H_mat.shape[0]} | Q len={Q_vec.shape[0]}')
assert H_mat.shape[1] == O_star.flatten().shape[0], 'H cols must equal image pixels'
assert H_mat.shape[0] == Q_vec.shape[0],            'H rows must equal Q length'
print('Shapes OK\n')





# training loop
print(f'Training for {num_iter} iterations...')

loss_history = []
best_loss    = float('inf')
best_O_hat   = None

# Early stopping
patience = 200
counter = 0
min_delta = 1e-4


os.makedirs('results/training_frames', exist_ok=True)

frames = []

for iteration in range(num_iter):
    

    optimizer.zero_grad()
    O_hat = model(O_star_t)

    physics_term = physics_loss(
        Q_t,
        O_hat,
        H_t,
        alpha
    )
    
    prior_term = torch.mean(
        (O_hat - O_star_t)**2
    )
    
    recon_term = torch.mean(
        (O_hat - gt_t)**2
    )
    
    loss = recon_term + 0.01 * physics_term

    loss.backward()

    # gradient clipping 
    torch.nn.utils.clip_grad_norm_(model.parameters(), max_norm=1.0)

    optimizer.step()
    scheduler.step(loss.item())

    loss_val = loss.item()
    loss_history.append(loss_val)



    if iteration % 50 == 0:

        frame = O_hat.detach().squeeze().cpu().numpy()

        frame = frame - frame.min()
        frame = frame / (frame.max() + 1e-8)

        frames.append(frame.copy())

        plt.figure(figsize=(4,4))
        plt.imshow(frame, cmap='gray')
        plt.title(f'Iteration {iteration}')
        plt.axis('off')

        plt.savefig(
            f'results/training_frames/frame_{iteration:05d}.png',
            bbox_inches='tight'
        )

        plt.close()



    if loss_val < best_loss - min_delta:

        best_loss = loss_val
        best_O_hat = O_hat.detach().squeeze().cpu().numpy().copy()
    
        counter = 0

    else:
        counter += 1



    if counter >= patience:
       print(f'\nEarly stopping at iteration {iteration}')
       break    


    if iteration % 200 == 0:
        mean_out = O_hat.detach().mean().item()
        max_out  = O_hat.detach().max().item()
        print(f'Iter {iteration:4d} | Loss: {loss_val:.4f} | '
              f'LR: {optimizer.param_groups[0]["lr"]:.6f} | '
              f'Mean: {mean_out:.4f} | Max: {max_out:.4f}')

print(f'Best loss: {best_loss:.6f}')


gif_frames = []

for frame in frames:

    gif_frames.append(
        (255 * frame).astype(np.uint8)
    )

imageio.mimsave(
    'results/unet_evolution.gif',
    gif_frames,
    duration=0.15
)

print('Saved: results/unet_evolution.gif')


# output
O_hat_np = best_O_hat.copy()
O_hat_np = O_hat_np - O_hat_np.min()
O_hat_np = O_hat_np / (O_hat_np.max() + 1e-8)


sio.savemat(output_path, {'O_hat': O_hat_np})
print(f'Saved: {output_path}')


fig, axes = plt.subplots(1, 4, figsize=(14, 4))

axes[0].imshow(gt,       cmap='gray'); axes[0].set_title('Ground Truth');    axes[0].axis('off')
axes[1].imshow(O_star,   cmap='gray'); axes[1].set_title('O* (pseudo-inv)'); axes[1].axis('off')
axes[2].imshow(O_hat_np, cmap='gray'); axes[2].set_title('Ô (U-Net)');       axes[2].axis('off')

axes[3].plot(loss_history)
axes[3].set_title('Loss curve')
axes[3].set_xlabel('Iteration')
axes[3].set_ylabel('Loss')
axes[3].set_yscale('log')

plt.tight_layout()
plt.savefig(f'results/figures/unet_result_p{p}.png', dpi=150)
plt.show()