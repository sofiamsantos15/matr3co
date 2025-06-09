from flask_wtf import FlaskForm
from wtforms import StringField, PasswordField, SelectField, SubmitField
from wtforms.validators import DataRequired, Length, Email

class LoginForm(FlaskForm):
    username = StringField('User', validators=[DataRequired()])
    password = PasswordField('Senha', validators=[DataRequired()])
    submit   = SubmitField('Iniciar Sessão')

class CategoryForm(FlaskForm):
    name   = StringField('Nome', validators=[DataRequired(), Length(max=100)])
    submit = SubmitField('Guardar Alterações')

class SubcategoryForm(FlaskForm):
    category = SelectField('Categoria', coerce=int, validators=[DataRequired()])
    name     = StringField('Nome',      validators=[DataRequired(), Length(max=100)])
    submit   = SubmitField('Guardar Alterações')

class UserForm(FlaskForm):
    username = StringField('User', validators=[DataRequired(), Length(max=150)])
    email    = StringField('Email',   validators=[DataRequired(), Email()])
    profile  = SelectField('Perfil',
                  choices=[('user','User'),('admin','Admin')],
                  validators=[DataRequired()])
    is_active  = SelectField('Estado do Utilizador',
                  choices=[('1','Ativo'),('0','Inativo')],
                  validators=[DataRequired()])
    submit   = SubmitField('Guardar Alterações')
