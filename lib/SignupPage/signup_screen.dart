// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:ijob_clone_app/Services/global_methods.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../Services/global_var.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> with TickerProviderStateMixin {
  late Animation<double> _animation;
  late AnimationController _animationController;

  final TextEditingController _fullNameTextController =
      TextEditingController(text: '');
  final TextEditingController _emailTextController =
      TextEditingController(text: '');
  final TextEditingController _passTextController =
      TextEditingController(text: '');
  final TextEditingController _phoneNumberController =
      TextEditingController(text: '');
  final TextEditingController _locationController =
      TextEditingController(text: '');

  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passFocusNode = FocusNode();
  final FocusNode _phoneNumberFocusNode = FocusNode();
  final FocusNode _posisitionCPFocusNode = FocusNode();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final _signUpFormKey = GlobalKey<FormState>();

  bool _obsecureText = true;
  bool _isLoading = false;
  String? imageUrl;

  File? imageFile;

  @override
  void dispose() {
    _animationController.dispose();
    _fullNameTextController.dispose();
    _emailTextController.dispose();
    _passTextController.dispose();
    _phoneNumberController.dispose();
    _locationController.dispose();
    _emailFocusNode.dispose();
    _passFocusNode.dispose();
    _phoneNumberFocusNode.dispose();
    _posisitionCPFocusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    _animationController =
        AnimationController(vsync: this, duration: const Duration(seconds: 20));
    _animation =
        CurvedAnimation(parent: _animationController, curve: Curves.linear)
          ..addListener(() {
            setState(() {});
          })
          ..addStatusListener((animationStatus) {
            if (animationStatus == AnimationStatus.completed) {
              _animationController.reset();
              _animationController.forward();
            }
          });
    _animationController.forward();
    super.initState();
  }

  void _showImageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Please choosen an option'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: () {
                //Create getFromCamera
                _getFromCamera();
              },
              child: Row(
                children: const [
                  Padding(
                    padding: EdgeInsets.all(3.5),
                    child: Icon(
                      Icons.camera,
                      color: Colors.purple,
                    ),
                  ),
                  Text(
                    'Camera',
                    style: TextStyle(
                      color: Colors.purple,
                    ),
                  ),
                ],
              ),
            ),
            InkWell(
              onTap: () {
                //Create getFromGallery
                _getFromGallery();
              },
              child: Row(
                children: const [
                  Padding(
                    padding: EdgeInsets.all(3.5),
                    child: Icon(
                      Icons.image,
                      color: Colors.purple,
                    ),
                  ),
                  Text(
                    'Gallery',
                    style: TextStyle(
                      color: Colors.purple,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _getFromCamera() async {
    XFile? pickedFile =
        await ImagePicker().pickImage(source: ImageSource.camera);
    _cropImage(pickedFile!.path);
    Navigator.pop(context);
  }

  void _getFromGallery() async {
    XFile? pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    _cropImage(pickedFile!.path);
    Navigator.pop(context);
  }

  void _cropImage(filePath) async {
    CroppedFile? croppedImage = await ImageCropper()
        .cropImage(sourcePath: filePath, maxHeight: 1080, maxWidth: 1080);
    if (croppedImage != null) {
      setState(() {
        imageFile = File(croppedImage.path);
      });
    }
  }

  void _submitFormOnSignUp() async {
    final isValid = _signUpFormKey.currentState!.validate();
    if (isValid) {
      if (imageFile == null) {
        GlobalMethod.showErrorDialog(
          error: 'Please pick an image',
          ctx: context,
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        await _auth.createUserWithEmailAndPassword(
          email: _emailTextController.text.trim().toLowerCase(),
          password: _passTextController.text.trim(),
        );
        final User? user = _auth.currentUser;
        final _uid = user!.uid;
        final ref = FirebaseStorage.instance
            .ref()
            .child('userImages')
            .child(_uid + '.jpg');
        await ref.putFile(imageFile!);
        imageUrl = await ref.getDownloadURL();
        FirebaseFirestore.instance.collection('users').doc(_uid).set({
          'id': _uid,
          'name': _fullNameTextController.text,
          'email': _emailTextController.text,
          'userImage': imageUrl,
          'phoneNumber': _phoneNumberController.text,
          'location': _locationController.text,
          'createdAt': Timestamp.now(),
        });
        Navigator.canPop(context) ? Navigator.pop(context) : null;
      } catch (error) {
        setState(() {
          _isLoading = false;
        });
        GlobalMethod.showErrorDialog(error: error.toString(), ctx: context);
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          CachedNetworkImage(
            imageUrl: signUpUrlImage,
            placeholder: (context, url) => Image.asset(
              'assets/images/wallpaper.jpg',
              fit: BoxFit.fill,
            ),
            errorWidget: (context, url, error) => const Icon(Icons.error),
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
            alignment: FractionalOffset(
              _animation.value,
              0,
            ),
          ),
          Container(
            color: Colors.black54,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 60,
              ),
              child: ListView(
                children: [
                  Form(
                    key: _signUpFormKey,
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            _showImageDialog();
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Container(
                              width: size.width * 0.24,
                              height: size.height * 0.14,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  width: 1,
                                  color: Colors.cyan,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: imageFile == null
                                    ? const Icon(
                                        Icons.camera_enhance_sharp,
                                        color: Colors.cyan,
                                        size: 30,
                                      )
                                    : Image.file(
                                        imageFile!,
                                        fit: BoxFit.fill,
                                      ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          textInputAction: TextInputAction.next,
                          onEditingComplete: () => FocusScope.of(context)
                              .requestFocus(_emailFocusNode),
                          keyboardType: TextInputType.name,
                          controller: _fullNameTextController,
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'This Field is missing';
                            } else {
                              return null;
                            }
                          },
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'Full name / company name',
                            hintStyle: TextStyle(color: Colors.white),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                            ),
                            errorBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.red),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          textInputAction: TextInputAction.next,
                          onEditingComplete: () => FocusScope.of(context)
                              .requestFocus(_passFocusNode),
                          keyboardType: TextInputType.emailAddress,
                          controller: _emailTextController,
                          validator: (value) {
                            if (value!.isEmpty || !value.contains('@')) {
                              return 'Please eneter a valid email address';
                            } else {
                              return null;
                            }
                          },
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'Email',
                            hintStyle: TextStyle(color: Colors.white),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                            ),
                            errorBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.red),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          textInputAction: TextInputAction.next,
                          focusNode: _phoneNumberFocusNode,
                          keyboardType: TextInputType.visiblePassword,
                          controller: _passTextController,
                          obscureText: !_obsecureText,
                          validator: (value) {
                            if (value!.isEmpty || value.length < 7) {
                              return 'Please enter a valid password';
                            } else {
                              return null;
                            }
                          },
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            suffixIcon: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _obsecureText = !_obsecureText;
                                });
                              },
                              child: Icon(
                                _obsecureText
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.white,
                              ),
                            ),
                            hintText: 'Password',
                            hintStyle: const TextStyle(color: Colors.white),
                            enabledBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                            ),
                            focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                            ),
                            errorBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.red),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          textInputAction: TextInputAction.next,
                          onEditingComplete: () => FocusScope.of(context)
                              .requestFocus(_posisitionCPFocusNode),
                          keyboardType: TextInputType.phone,
                          controller: _phoneNumberController,
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'This Field is missing';
                            } else {
                              return null;
                            }
                          },
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'Phone Number',
                            hintStyle: TextStyle(color: Colors.white),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                            ),
                            errorBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.red),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          textInputAction: TextInputAction.next,
                          onEditingComplete: () => FocusScope.of(context)
                              .requestFocus(_posisitionCPFocusNode),
                          keyboardType: TextInputType.text,
                          controller: _locationController,
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'This Field is missing';
                            } else {
                              return null;
                            }
                          },
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'Address',
                            hintStyle: TextStyle(color: Colors.white),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                            ),
                            errorBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.red),
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 25,
                        ),
                        _isLoading
                            ? Center(
                                child: Container(
                                  width: 70,
                                  height: 70,
                                  child: const CircularProgressIndicator(),
                                ),
                              )
                            : MaterialButton(
                                onPressed: () {
                                  //Create submit form on sign
                                  _submitFormOnSignUp();
                                },
                                color: Colors.cyan,
                                elevation: 8,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(13),
                                ),
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 11),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Text(
                                        'SignUp',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                        const SizedBox(height: 25),
                        Center(
                          child: RichText(
                            text: TextSpan(
                              children: [
                                const TextSpan(
                                  text: 'Already registered?',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const TextSpan(
                                  text: "  ",
                                ),
                                TextSpan(
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () => Navigator.canPop(context)
                                        ? Navigator.pop(context)
                                        : null,
                                  text: 'Login',
                                  style: const TextStyle(
                                    color: Colors.cyan,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
