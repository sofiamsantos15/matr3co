from flask_wtf import FlaskForm
from wtforms import StringField, PasswordField, SubmitField
from wtforms.validators import DataRequired, Email, EqualTo, Length

class LoginForm(FlaskForm):
    email = StringField('Email', validators=[DataRequired(), Email()])
    password = PasswordField('Password', validators=[DataRequired()])
    submit = SubmitField('Iniciar Sessão')

class RegistrationForm(FlaskForm):
    username = StringField('Nome de Utilizador',
        validators=[DataRequired(), Length(min=3, max=150)])
    email = StringField('Email', validators=[DataRequired(), Email()])
    password = PasswordField('Password',
        validators=[DataRequired(), Length(min=6)])
    confirm = PasswordField('Confirmar Password',
        validators=[DataRequired(), EqualTo('password',
            message='As passwords não coincidem.')])
    submit = SubmitField('Criar Conta')

class EditProfileForm(FlaskForm):
    username = StringField('Nome de Utilizador',
        validators=[DataRequired(), Length(min=3, max=150)])
    email = StringField('Email', validators=[DataRequired(), Email()])
    password = PasswordField('Nova Password',
        validators=[Length(min=6)],
        description='Deixe vazio se não quiser alterar')
    confirm = PasswordField('Confirmar Nova Password',
        validators=[EqualTo('password',
            message='As passwords não coincidem.')],
        description='Confirme a nova password')
    submit = SubmitField('Guardar Alterações')
