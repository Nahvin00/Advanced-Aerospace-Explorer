clear all, close all,  clc

global img_int; global fov; global dof; global num;
dist_x = 0.0; dist_y = 0.0; tarea = 0.0; coll_time = 0; img_temp = 0;

[file,path] = uigetfile('*.png',...
'Select more Than One Image', ...
'MultiSelect', 'on');
num = size(file);
num = num(2);

user_input()
while  fov <= 0 || fov >= 180 || dof <= 0 || img_int <= 0
    f = msgbox('Invalid Value', 'Error','error');
    user_input();
end
ori_range = 2 * dof * tand(fov/2);

try
    for i = 1:num
        I = imread(string(append(path,file(i))));
        I_filt = img_prep(I);
    
        if i == 1
            img_1 = I_filt;
        elseif i == num
            img_2 = I_filt;
        end
        all_properties = regionprops('table',I_filt,'all');
        coor = all_properties.Centroid;
        coor_x(i) = coor(1);
        coor_y(i) = coor(2);
        if i > 1
            dist_x = dist_x + (coor_x(i)-coor_x(i-1));
            dist_y = dist_y + (coor_y(i-1)-coor_y(i));
        end
        area_(i) = all_properties.Area;
        area_;
        if i > 1
            tarea = tarea + (area_(i)/area_(i-1));
        end
        img_temp = img_temp + I_filt;
    end
    new_img = img_2 - img_1;
    figure, imshow(new_img), title('Scalling')
    
    img_range = length(I_filt);
    img_area = img_range^2;
    ori_img_ratio = ori_range/img_range;
    
    velo_x = dist_x/(img_int*num);
    velo_y = dist_y/(img_int*num);
    tscale = 1 + (tarea/(img_int*num));
    res_velo = sqrt(velo_x^2 + velo_y^2);
    res_angle = atand(abs(velo_y/velo_x));

    if velo_x < 0 && velo_y < 0
        res_dir = "South-East";
    elseif velo_x > 0 && velo_y > 0
        res_dir = "North-West";
    elseif velo_x < 0 && velo_y > 0
        res_dir = "North-East";
    elseif velo_x > 0 && velo_y < 0
        res_dir = "South-West";
    else
        res_dir = "";
    end
    
    coll_time = log(img_area*0.9/area_(num))/log(tscale);
    
    figure, imshow(img_temp), title('Movement')
    
    fprintf("\n\n")
    fprintf("X-axis Velocity: %f Km/s\n",velo_x*ori_img_ratio)
    fprintf("Y-axis Velocity: %f Km/s\n",velo_y*ori_img_ratio)
    if res_dir ~= ""
        res_str = strjoin(['Resultant Velocity: ',num2str(res_velo*ori_img_ratio),' Km/s ',num2str(res_angle),'° ',res_dir],'');
        fprintf(res_str);
    end
    fprintf("\n\n")
    fprintf("Scalling: %f pixels^2/s\n",tscale)
    fprintf("Time of collision: %f s\n",coll_time)
    
    if coll_time < 10
        f = msgbox('Immediately Evacuate!!!', 'Error','error');
    end

catch
    f = msgbox('Please select more than one image file', 'Error','error');
end

function user_input()
    global img_int; global fov; global dof;
    prompt = 'Image interval(s): ';
    img_int = input(prompt);
    prompt = 'FOV(°): ';
    fov = input(prompt);
    prompt = 'DOF(Km): ';
    dof = input(prompt);
end

function img= img_prep(I)
    I_resize = imresize(I,0.1);
    I_gray = rgb2gray(I_resize);
    I_bin = imbinarize(I_gray,'adaptive');
    I_fill = imfill(I_bin,'holes');
    img = bwareafilt(I_fill,[2000 Inf]);
end

